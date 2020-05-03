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

backup:
	$(MAKE) seal
	vault operator migrate -config config/vault/backup.hcl
	$(MAKE) restart

begin:
	docker-compose build
	$(MAKE) recreate
	sleep 5

end:
	$(MAKE) clean
	$(MAKE) down 

root-login:
	@vault login "$(shell cat backup/.vault-root-token)" >/dev/null

seal:
	$(MAKE) root-login
	vault operator seal

clean:
	$(MAKE) seal

ddb s3 file:
	ln -nfs vault-$@ config/vault
	$(MAKE) begin
