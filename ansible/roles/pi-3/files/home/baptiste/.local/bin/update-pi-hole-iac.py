#!/usr/bin/env python3

import logging
import shutil
import jwt
import os
import requests
import time
import yaml
import subprocess

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
GIT_REPO_URL: str = "https://github.com/bgaillard/homelab.git"


def create_gh_jwt(private_key_path: str, client_id: str) -> str:
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


def create_gh_token(jwt: str, installation_id: str) -> str:
    url: str = f"https://api.github.com/app/installations/{installation_id}/access_tokens"
    headers: dict[str, str] = {
        "Authorization": f"Bearer {jwt}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28"
    }
    response = requests.post(url, headers=headers)
    response.raise_for_status()
    return cast(str, cast(JSON, response.json())["token"])


def create_pr(token: str, title: str, body: str, head: str, base: str) -> JSON:
    url: str = "https://api.github.com/repos/bgaillard/homelab/pulls"
    headers: dict[str, str] = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28"
    }
    response = requests.post(
        url, 
        headers=headers, 
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


def get(endpoint: str, sid: str) -> JSON:
    """Make a GET request to the Pi-hole API."""
    response = requests.get(f"{pi_hole_api_url}/{endpoint}?sid={sid}")
    response.raise_for_status()
    return cast(JSON, response.json())


def post(endpoint: str, data: JSON) -> JSON:
    """Make a POST request to the Pi-hole API."""
    url = f"{pi_hole_api_url}/{endpoint}"
    headers = {"Content-Type": "application/json"}
    response = requests.post(url, headers=headers, json=data)
    response.raise_for_status()
    return cast(JSON, response.json())


def auth(pi_hole_password: str) -> str:
    """Authenticate with the Pi-hole API and return the session ID."""
    response: JSON = post("auth", {"password": pi_hole_password})
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

    # Create a temporary workspace directory
    workspace_dir: str | None = None
    with TemporaryDirectory(prefix="update-pi-hole-iac", delete=False) as tmp_dir:
        workspace_dir = tmp_dir
    project_dir: str = os.path.join(workspace_dir, "homelab")
    logger.info(f"Using workspace directory: {workspace_dir}")
    _ = git(["clone", GIT_REPO_URL, project_dir], workspace_dir)

    # Authenticate
    sid: str = auth(pi_hole_password)
    logger.info(f"Authenticated with SID: {sid}")

    # Get and process Pi-hole domains
    logging.info("Processing Pi-hole domains...")
    domains: list[PiHoleDomain] = cast(list[PiHoleDomain], get("domains", sid)["domains"])
    domains = process_domains(domains)
    with open(os.path.join(project_dir, "ansible/pi-hole-domains.yml"), "w") as file:
        yaml.dump({"pi_hole_domains": domains}, file)

    # Get and process Pi-hole lists
    logging.info("Processing Pi-hole lists...")
    lists: list[PiHoleList] = cast(list[PiHoleList], get("lists", sid)["lists"])
    lists = process_lists(lists)
    with open(os.path.join(project_dir, "ansible/pi-hole-lists.yml"), "w") as file:
        yaml.dump({"pi_hole_lists": lists}, file)

    # Check for changes in the Git repository
    logging.info("Checking for changes in the Git repository...")
    completed_process: CompletedProcess[str] = git(["status", "--porcelain"], project_dir, check=False)

    # Get a Github token to then create a PR as the IaC Updater Github App
    logging.info("Creating a JWT for the IaC Updater Github App...")
    jwt: str = create_gh_jwt(iac_updater_private_key_path, iac_updater_client_id)
    logging.info("Creating token for the IaC Updater Github App installation...")
    github_app_token: str = create_gh_token(jwt, iac_updater_installation_id)

    # If there are changes commit and push
    if "M ansible/pi-hole-" in completed_process.stdout:
        logging.info("Changes detected, creating a new branch and committing changes...")

        # Create a new branch
        branch_name: str = "update-pi-hole-iac"
        _ = git(["checkout", "-b", branch_name], project_dir)
        _ = git(["add", "."], project_dir)
        _ = git(["commit", "--message", "feat: Update Pi-Hole IaC"], project_dir)
        _ = git(["push", "--set-upstream", "origin", branch_name], project_dir)
        _ = create_pr(
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


if __name__ == "__main__":
    main()
