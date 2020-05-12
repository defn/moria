SHELL := /bin/bash

.PHONY: docs backups

menu:
	@perl -ne 'printf("%10s: %s\n","$$1","$$2") if m{^([\w+-]+):[^#]+#\s(.+)$$}' Makefile

all: # Run everything except build
	$(MAKE) fmt
	$(MAKE) lint
	$(MAKE) docs

fmt: # Format drone fmt
	@echo
	drone exec --pipeline $@

lint: # Run drone lint
	@echo
	drone exec --pipeline $@

docs: # Build docs
	@echo
	drone exec --pipeline $@

build: # Build container
	@echo
	drone exec --pipeline $@

edit:
	docker-compose -f docker-compose.docs.yml up --quiet-pull

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

include Makefile.site

test:
	$(MAKE) begin
	$(MAKE) end

migrate-ddb migrate-s3:
	$(MAKE) seal
	$(RENEW) vault operator migrate -config config/$@.hcl
	$(MAKE) restart
	$(MAKE) wait

backup:
	$(MAKE) seal
	$(RENEW) vault operator migrate -config config/vault/backup.hcl
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
