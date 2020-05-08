SHELL := /bin/bash

.PHONY: backup

include Makefile.site

logs: # Logs for docker-compose
	docker-compose logs -f

up: # Run home container with docker-compose
	$(RENEW) docker-compose up -d

down: # Shut down home container
	docker-compose down

restart: # Restart home container
	$(RENEW) docker-compose restart

recreate: # Recreate home container
	-$(MAKE) down 
	$(MAKE) up

test:
	$(MAKE) begin
	$(MAKE) end

migrate:
	$(MAKE) seal
	vault operator migrate -config config/migrate.hcl
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
	@vault login "$(shell cat backup/.vault-root-token)" >/dev/null

seal:
	$(MAKE) root-login
	vault operator seal

clean:
	$(MAKE) seal

ddb s3 file-ddb file-s3:
	ln -nfs vault-$@ config/vault
	docker-compose build
	$(MAKE) begin
