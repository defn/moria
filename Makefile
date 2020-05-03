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
	$(MAKE) seal || true
	vault operator migrate -config config/migrate.hcl
	$(MAKE) down
	$(MAKE) begin

backup:
	$(MAKE) seal || true
	vault operator migrate -config config/backup.hcl
	cd backup && git add -u . && git commit -m backup
	$(MAKE) down
	$(MAKE) begin

begin:
	docker-compose build
	$(MAKE) recreate

end:
	$(MAKE) clean
	$(MAKE) down 

root-login:
	@vault login "$(shell cat backup/.vault-root-token)" >/dev/null

seal:
	vault operator seal

clean:
	$(MAKE) seal
