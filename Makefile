SHELL := /bin/bash

.PHONY: backups

menu:
	@perl -ne 'printf("%10s: %s\n","$$1","$$2") if m{^([\w+-]+):[^#]+#\s(.+)$$}' Makefile

migrate-ddb migrate-s3:
	$(MAKE) seal
	vault operator migrate -config config/$@.hcl
	$(MAKE) restart
	$(MAKE) wait

backup:
	$(MAKE) seal
	vault operator migrate -config config/vault/backup.hcl
	$(MAKE) restart
	$(MAKE) wait

begin:
	$(MAKE) recreate
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

clean:
	$(MAKE) seal

ddb s3 file-ddb file-s3:
	ln -nfs vault-$@ config/vault
	docker-compose build
	$(MAKE) begin
