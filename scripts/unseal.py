import json
import os
import requests
import sys
sys.path.append('scripts/')
from pyinfra import host, local
from pyinfra.operations import python, server
from status import status

SHELL = '/usr/bin/env bash'

# curl --request PUT --data '{"key": "abcd1234..."}' https://vault.$KITT_DOMAIN/v1/sys/unseal
def unseal():
    print('Unseal Moria')
    url = "vault.{}".format(os.getenv("KITT_DOMAIN", "kitt.run"))
    for index in range(1, 5):
        key = local.shell('pass moria/keys_{}'.format(index))
        try:
            req = requests.put("https://{}/v1/sys/unseal".format(url), data = '{{"key": "{}"}}'.format(key))
            req.raise_for_status()
        except requests.exceptions.RequestException as e:
            raise SystemExit(e)

unseal()
mStatus = status()
if mStatus['initialized']:
    print('Moria initialized')
if not mStatus['sealed']:
    print('Moria unsealed')
