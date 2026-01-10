# type: ignore
# pyright: reportMissingTypeStubs=false, reportUnknownArgumentType=false, reportUnknownMemberType=false, reportUnknownParameterType=false, reportUnknownVariableType=false, reportMissingParameterType=false, reportUnannotatedClassAttribute=false

from __future__ import annotations

import yaml

from subprocess import PIPE, Popen

from ansible.errors import AnsibleError
from ansible.module_utils.common.text.converters import to_bytes, to_text
from ansible.plugins.lookup import LookupBase

DOCUMENTATION = '''
    name: bitwarden_attachment
    author: Baptiste Gaillard (@bgaillard) <baptiste.gaillard@gmail.com>
    version_added: "1.0.0"
    short_description: Retrieve an attachment from a Bitwarden item.
    description:
        - This lookup plugin retrieves an attachment from a Bitwarden item using the Bitwarden CLI.
    options:
        attachment:
            description: The name of the attachment to retrieve.
            required: true
            type: str
        item_id:
            description: The ID of the Bitwarden item containing the attachment.
            required: true
            type: str
        bw_session:
            description: Pass session key instead of reading from env.
            type: str
'''


class BitwardenException(AnsibleError):
    pass

# The source code of this plugin is largely inspired by the Ansible 'bitwarden' community plugin.
#
# @see https://github.com/ansible-collections/community.general/blob/main/plugins/lookup/bitwarden.py

class Bitwarden:
    def __init__(self, path="bw"):
        self._cli_path = path
        self._session = None

    @property
    def cli_path(self):
        return self._cli_path

    @property
    def session(self):
        return self._session

    @session.setter
    def session(self, value):
        self._session = value

    @property
    def unlocked(self):
        out, _ = self._run(["status"], stdin="")
        decoded = AnsibleJSONDecoder().raw_decode(out)[0]
        return decoded["status"] == "unlocked"

    def _run(self, args, stdin=None, expected_rc=0):
        if self.session:
            args += ["--session", self.session]

        p = Popen([self.cli_path] + args, stdout=PIPE, stderr=PIPE, stdin=PIPE)
        out, err = p.communicate(to_bytes(stdin))
        rc = p.wait()
        if rc != expected_rc:
            if len(args) > 2 and args[0] == "get" and args[1] == "item" and b"Not found." in err:
                return "null", ""
            raise BitwardenException(err.decode("utf-8"))
        return to_text(out, errors="surrogate_or_strict"), to_text(err, errors="surrogate_or_strict")

    def get_attachment(self, attachment, item_id):
        args = [
            'get', 'attachment', attachment, '--itemid', item_id, '--output', '/tmp/pi_hole_configuration.yml'
        ]

        out, _ = self._run(args)
        pi_hole_config = {}

        with open('/tmp/pi_hole_configuration.yml', 'r') as file:
            pi_hole_config = yaml.safe_load(file)
            #pi_hole_config = AnsibleJSONDecoder().raw_decode(file.read())

        return pi_hole_config


class LookupModule(LookupBase):
    def run(self, terms=None, variables=None, **kwargs):
        self.set_options(var_options=variables, direct=kwargs)
        attachment = self.get_option("attachment")
        item_id = self.get_option("item_id")
        _bitwarden.session = self.get_option("bw_session")

        if not _bitwarden.unlocked:
            raise AnsibleError("Bitwarden Vault locked. Run 'bw unlock'.")

        if not terms:
            terms = [None]

        results = [
            _bitwarden.get_attachment(attachment, item_id)
        ]

        return results


_bitwarden = Bitwarden()
