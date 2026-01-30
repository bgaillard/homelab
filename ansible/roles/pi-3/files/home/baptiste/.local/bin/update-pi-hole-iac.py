#!/usr/bin/env python3

import json
import hvac
import logging
import shutil
import jwt
import os
import requests
import time
import yaml
import subprocess

from hvac.api.auth_methods.approle import AppRole
from hvac.api.secrets_engines.kv import Kv
from hvac.api.secrets_engines.kv_v2 import KvV2
from logging import Logger
from tempfile import TemporaryDirectory
from typing import cast
from subprocess import CompletedProcess

# Define utility types
type JSON = dict[str, str | int | bool | None | list[str] | list[int] | list[bool] | JSON]
type PiHoleDomain = dict[str, str | int | bool | list[int]]
type PiHoleList = dict[str, str | int | bool | list[int]]

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger: Logger = logging.getLogger(__name__)

# IaC Updater configuration
iac_updater_client_id: str | None = None
iac_updater_installation_id: str | None = None
iac_updater_private_key_path: str | None = None

# Pi-hole API configuration
pi_hole_api_url: str | None = None
pi_hole_password: str | None = None

# Github repository URL
GITHUB_USER: str = "bgaillard"
GITHUB_REPO: str = "homelab"
GIT_REPO_URL: str = f"https://github.com/{GITHUB_USER}/{GITHUB_REPO}.git"

# VAULT
VAULT_ADDR: str = os.getenv("VAULT_ADDR", "https://vault:8200")


########################################################################################################################
# GitHub functions
########################################################################################################################
def github_create_api_headers(token: str) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28"
    }

def github_create_api_url(endpoint: str) -> str:
    return f"https://api.github.com/{endpoint}"

def github_create_jwt(private_key_path: str, client_id: str) -> str:
    # @see https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-json-web-token-jwt-for-a-github-app#example-using-python-to-generate-a-jwt
    signing_key: bytes | None = None

    with open(private_key_path, 'rb') as pem_file:
        signing_key = pem_file.read()

    payload = {
        # Issued at time
        'iat': int(time.time()),
        # JWT expiration time (10 minutes maximum)
        'exp': int(time.time()) + 600,
        # GitHub App's client ID
        'iss': client_id
    }

    # Create JWT
    return jwt.encode(payload, signing_key, algorithm='RS256')

def github_create_pr(token: str, title: str, body: str, head: str, base: str) -> JSON:
    response = requests.post(
        github_create_api_url(f"repos/{GITHUB_USER}/{GITHUB_REPO}/pulls"), 
        headers=github_create_api_headers(token),
        json={
            "title": title,
            "body": body,
            "head": head,
            "base": base
        }
    )
    try:
        response.raise_for_status()
    except requests.HTTPError as e:
        logger.error(f"Failed to create pull request: {e}")
        logger.error(f"Response: {response.text}")
        raise
    return cast(JSON, response.json())

def github_create_token(jwt: str, installation_id: str) -> str:
    response = requests.post(
        github_create_api_url(f"app/installations/{installation_id}/access_tokens"), 
        headers=github_create_api_headers(jwt)
    )
    response.raise_for_status()
    return cast(str, cast(JSON, response.json())["token"])


def git(args: list[str], cwd: str, check: bool = True) -> CompletedProcess[str]:
    return run(args=["git"] + args, cwd=cwd, check=check)


def run(args: list[str], cwd: str, check: bool = True, env: dict[str, str] | None = None) -> CompletedProcess[str]:
    completed_process: CompletedProcess[str] | None = None

    try:
        completed_process = subprocess.run(
            args,
            cwd=cwd, 
            check=check, 
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            env=env
        )
    except subprocess.CalledProcessError as e:
        logger.error(f"Command '{' '.join(args)}' failed with exit code {e.returncode}")
        logger.error(f"Stdout: {cast(str, e.stdout)}")
        logger.error(f"Stderr: {cast(str, e.stderr)}")
        raise

    return completed_process


########################################################################################################################
# Pi-hole functions
########################################################################################################################
def pi_hole_get(endpoint: str, sid: str) -> JSON:
    """Make a GET request to the Pi-hole API."""
    response = requests.get(f"{pi_hole_api_url}/{endpoint}?sid={sid}")
    response.raise_for_status()
    return cast(JSON, response.json())

def pi_hole_post(endpoint: str, data: JSON) -> JSON:
    """Make a POST request to the Pi-hole API."""
    url = f"{pi_hole_api_url}/{endpoint}"
    headers = {"Content-Type": "application/json"}
    response = requests.post(url, headers=headers, json=data)
    response.raise_for_status()
    return cast(JSON, response.json())

def pi_hole_auth(pi_hole_password: str) -> str:
    """Authenticate with the Pi-hole API and return the session ID."""
    response: JSON = pi_hole_post("auth", {"password": pi_hole_password})
    return cast(str, cast(JSON, response["session"])["sid"])


def process_domains(domains: list[PiHoleDomain]) -> list[PiHoleDomain]:
    """Sort domains alphabetically with proper subdomain sorting."""

    # Remove non-essential fields
    for domain in domains:
        del domain["date_added"]
        del domain["date_modified"]
        del domain["unicode"]

    # Split domains into parts for proper sorting
    def domain_key(domain: PiHoleDomain) -> tuple[str, ...]:
        domain_value: str = cast(str, domain["domain"])
        parts = domain_value.split(".")
        _ = parts.pop()
        parts.reverse()  # Reverse to sort by TLD first

        return tuple(parts)

    # Sort by domain parts
    domains.sort(key=domain_key)

    # Update IDs to be sequential
    for i, domain in enumerate(domains, 1):
        domain["id"] = i

    return domains


def process_lists(lists: list[PiHoleList]) -> list[PiHoleList]:
    """Process Pi-hole lists if needed."""

    for lst in lists:
        del lst["abp_entries"]
        del lst["date_added"]
        del lst["date_modified"]
        del lst["date_updated"]
        del lst["invalid_domains"]

        del lst["number"]
        del lst["status"]

    lists.sort(key=lambda x: x["comment"])

    # Update IDs to be sequential
    for i, lst in enumerate(lists, 1):
        lst["id"] = i

    # Placeholder for any list processing logic
    return lists


def update_domains_and_lists(
    sid: str, 
    iac_updater_client_id: str,
    iac_updater_installation_id: str,
    iac_updater_private_key_path: str
) -> None:

    # Create a temporary workspace directory
    workspace_dir: str | None = None
    with TemporaryDirectory(prefix="update-pi-hole-iac", delete=False) as tmp_dir:
        workspace_dir = tmp_dir
    project_dir: str = os.path.join(workspace_dir, "homelab")
    logger.info(f"Using workspace directory: {workspace_dir}")
    _ = git(["clone", GIT_REPO_URL, project_dir], workspace_dir)

    # Get and process Pi-hole domains
    logging.info("Processing Pi-hole domains...")
    domains: list[PiHoleDomain] = cast(list[PiHoleDomain], pi_hole_get("domains", sid)["domains"])
    domains = process_domains(domains)
    with open(os.path.join(project_dir, "ansible/pi-hole-domains.yml"), "w") as file:
        yaml.dump({"pi_hole_domains": domains}, file)

    # Get and process Pi-hole lists
    logging.info("Processing Pi-hole lists...")
    lists: list[PiHoleList] = cast(list[PiHoleList], pi_hole_get("lists", sid)["lists"])
    lists = process_lists(lists)
    with open(os.path.join(project_dir, "ansible/pi-hole-lists.yml"), "w") as file:
        yaml.dump({"pi_hole_lists": lists}, file)

    # Check for changes in the Git repository
    logging.info("Checking for changes in the Git repository...")
    completed_process: CompletedProcess[str] = git(["status", "--porcelain"], project_dir, check=False)

    # Get a Github token to then create a PR as the IaC Updater Github App
    logging.info("Creating a JWT for the IaC Updater Github App...")
    jwt: str = github_create_jwt(iac_updater_private_key_path, iac_updater_client_id)
    logging.info("Creating token for the IaC Updater Github App installation...")
    github_app_token: str = github_create_token(jwt, iac_updater_installation_id)

    # If there are changes commit and push
    if "M ansible/pi-hole-" in completed_process.stdout:
        logging.info("Changes detected, creating a new branch and committing changes...")

        # Create a new branch
        branch_name: str = "update-pi-hole-iac"
        _ = git(["checkout", "-b", branch_name], project_dir)
        _ = git(["add", "."], project_dir)
        _ = git(["commit", "--message", "feat: Update Pi-Hole IaC"], project_dir)
        _ = git(["push", "--set-upstream", "origin", branch_name], project_dir)
        _ = github_create_pr(
            token=github_app_token,
            title="feat: Update Pi-Hole IaC",
            body="Automated update of Pi-Hole domains and lists.",
            head=branch_name,
            base="main"
        )

        logging.info("Changes committed and pull request created.")

    # Cleanup the workspace directory
    logging.info("Cleaning up workspace directory...")
    shutil.rmtree(workspace_dir)


def update_pi_hole_configuration(sid: str) -> None:
    role_id: str | None = None
    secret_id: str | None = None

    # Get the Pi-hole configuration
    config: JSON = pi_hole_get("config", sid)
    config = cast(JSON, config["config"])
    config_dhcp: JSON = cast(JSON, config["dhcp"])
    config_dns: JSON = cast(JSON, config["dns"])
    pi_hole_configuration: JSON = {
        'config': {
            'dhcp': {
                'active': config_dhcp["active"],
                'end': config_dhcp["end"],
                'hosts': config_dhcp["hosts"],
                'router': config_dhcp["router"],
                'start': config_dhcp["start"]
            },
            'dns': {
                'hosts': config_dns["hosts"],
                'upstreams': config_dns["upstreams"]
            }
        }
    }

    # Get the IaC Updater AppRole credentials
    with open(f"{os.getenv("HOME")}/.vault/approle-pi-hole-iac-updater.json", "r") as json_file:
        approle_credentials: dict[str, str] = cast(dict[str, str], json.load(json_file))
        role_id = approle_credentials["role_id"]
        secret_id = approle_credentials["secret_id"]

    # Login to Vault
    client: hvac.Client = vault_login(vault_addr=VAULT_ADDR, role_id=role_id, secret_id=secret_id)

    # Gets the old Pi-hole configuration from Vault
    old_pi_hole_configuration: JSON = vault_get_pi_hole_configuration(client)

    # If the new configuration is different, update it in Vault
    if pi_hole_configuration != old_pi_hole_configuration:
        logger.info("Pi-hole configuration has changed, updating it in Vault...")
        vault_update_pi_hole_configuration(client, pi_hole_configuration)
        logger.info("Pi-hole configuration updated in Vault.")
    else:
        logger.info("Pi-hole configuration has not changed, no update needed.")


########################################################################################################################
# Vault functions
########################################################################################################################
def vault_get_pi_hole_configuration(client: hvac.Client) -> JSON:
    kv: Kv = cast(Kv, client.secrets.kv)
    kv_v2: KvV2 = cast(KvV2, kv.v2)

    secret_version_response = kv_v2.read_secret_version(  # pyright: ignore[reportUnknownMemberType, reportUnknownVariableType]
        mount_point='kv',
        path='pi-hole'
    )

    return cast(JSON, secret_version_response['data']['data']['pi_hole_configuration'])

def vault_login(vault_addr: str, role_id: str, secret_id: str) -> hvac.Client:
    client: hvac.Client = hvac.Client(
        url=vault_addr,
        # FIXME: Insecure, for testing purposes only
        verify=False
    )
    approle: AppRole = cast(AppRole, client.auth.approle)

    approle.login(role_id=role_id, secret_id=secret_id)  # pyright: ignore[reportUnknownMemberType]

    return client

def vault_update_pi_hole_configuration(client: hvac.Client, configuration: JSON) -> None:
    kv: Kv = cast(Kv, client.secrets.kv)
    kv_v2: KvV2 = cast(KvV2, kv.v2)

    kv_v2.create_or_update_secret(  # pyright: ignore[reportUnknownMemberType]
        mount_point='kv',
        path='pi-hole',
        secret={'pi_hole_configuration': configuration}
    )


def main():
    global iac_updater_client_id
    global iac_updater_installation_id
    global iac_updater_private_key_path
    global pi_hole_api_url
    global pi_hole_password

    iac_updater_client_id = os.getenv("IAC_UPDATER_CLIENT_ID")
    iac_updater_installation_id = os.getenv("IAC_UPDATER_INSTALLATION_ID")
    iac_updater_private_key_path = os.getenv(
        "IAC_UPDATER_PRIVATE_KEY_PATH", 
        f"{os.getenv("HOME")}/.github/iac-updater.private-key.pem"
    )
    if iac_updater_client_id is None:
        raise ValueError("IAC_UPDATER_CLIENT_ID environment variable is not set!")
    if iac_updater_installation_id is None:
        raise ValueError("IAC_UPDATER_INSTALLATION_ID environment variable is not set!")
    pi_hole_api_url = os.getenv("PI_HOLE_API_URL", "http://pi.hole/api")
    pi_hole_password = os.getenv("PI_HOLE_PASSWORD")
    if pi_hole_password is None:
        raise ValueError("PI_HOLE_PASSWORD environment variable is not set!")


    # Authenticate
    sid: str = pi_hole_auth(pi_hole_password)
    logger.info(f"Authenticated with SID: {sid}")

    # Update domains and lists in Github repository
    update_domains_and_lists(
        sid,
        iac_updater_client_id,
        iac_updater_installation_id,
        iac_updater_private_key_path
    )

    # Update Pi-hole configuration in Vault
    update_pi_hole_configuration(sid)


if __name__ == "__main__":
    main()
