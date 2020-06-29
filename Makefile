SHELL := /bin/bash

.PHONY: backup

menu:
	@perl -ne 'printf("%10s: %s\n","$$1","$$2") if m{^([\w+-]+):[^#]+#\s(.+)$$}' Makefile

migrate-ddb migrate-s3:
	$(MAKE) seal
	vault operator migrate -config config/$@.hcl
	kitt restart
	$(MAKE) wait

backup:
	$(MAKE) seal
	vault operator migrate -config config/vault/backup.hcl
	kitt restart
	$(MAKE) wait

begin:
	kitt recreate
	$(MAKE) wait

end:
	$(MAKE) clean
	$(MAKE) down 

wait:
	@set -x; while true; do if [[ "$$(vault status -format json | jq -r '.sealed')" == "false" ]]; then break; fi; date; sleep 1; done

root-login:
	@vault login "$(shell pass moria-root-token)" >/dev/null

seal:
	$(MAKE) root-login
	vault operator seal

init:
	./scripts/init
	pass import -f bitwarden .init.csv
	$(MAKE) unseal

unseal:
	./scripts/unseal-pass

clean:
	$(MAKE) seal

ddb s3 file-ddb file-s3:
	ln -nfs vault-$@ config/vault
	docker-compose build
	$(MAKE) begin
