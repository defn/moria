import json
import os
import requests
from pyinfra import host, local
from pyinfra.operations import python, server

SHELL = '/usr/bin/env bash'
path = os.path.split(os.path.dirname(os.path.realpath(__file__)))[0]
url = "vault.{}".format(os.getenv("KITT_DOMAIN", "kitt.run"))

def initialize():
    status = {}
    init = {}

    #curl https://vault.$KITT_DOMAIN/v1/sys/seal-status
    try:
        req = requests.get("https://{}/v1/sys/seal-status".format(url))
        req.raise_for_status()
        status = req.json()
    except requests.exceptions.RequestException as e:
        raise SystemExit(e)

    #curl --request PUT --data '{"secret_shares": 5, "secret_threshold": 3}' https://vault.$KITT_DOMAIN/v1/sys/init
    if "initialized" in status and not status["initialized"]:
        server.shell({'Initializing Moria'}, '')
        try:
            req = requests.put("https://{}/v1/sys/init".format(url), data = '{"secret_shares": 5, "secret_threshold": 3}')
            req.raise_for_status()
            init = req.json()
        except requests.exceptions.RequestException as e:
            raise SystemExit(e)

    return init

if host.fact.which('pass'):

    init = initialize()
    if init:
        for index in init:
            if isinstance(init[index], list):
                if len(init[index]) > 0:
                    for objIndex, objItem in enumerate(init[index]):
                        server.shell({'Import moria key {0}_{1}'.format(index, objIndex + 1)}, 'echo {0} | pass insert -e moria/{1}_{2}'.format(objItem, index, objIndex + 1))
            else:
                server.shell({'Import moria key {}'.format(index)}, 'echo {0} | pass insert -e moria/{1}'.format(init[index], index))
        server.shell({'Pass git push'}, 'pass git push')

    # curl --request PUT --data '{"key": "abcd1234..."}' https://vault.$KITT_DOMAIN/v1/sys/unseal
    server.shell({'Unsealing moria'}, '') 
    for index in range(1, 5):
        key = local.shell('pass moria/keys_{}'.format(index))
        try:
            req = requests.put("https://{}/v1/sys/unseal".format(url), data = '{{"key": "{}"}}'.format(key))
            req.raise_for_status()
        except requests.exceptions.RequestException as e:
            raise SystemExit(e)

else:
    python.raise_exception(OSError, 'please ensure you have password-store installed and configured (passwordstore.org)')
