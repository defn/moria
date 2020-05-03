SHELL := /bin/bash

.PHONY: backup

include Makefile.site

logs: # Logs for docker-compose
	docker-compose logs -f

up: # Run home container with docker-compose
	docker-compose up -d

down: # Shut down home container
	docker-compose down

restart: # Restart home container
	docker-compose restart

recreate: # Recreate home container
	-$(MAKE) down 
	$(MAKE) up

test:
	$(MAKE) begin
	$(MAKE) end

migrate:
	$(MAKE) renew
	$(MAKE) seal || true
	$(MAKE) seal2 || true
	$(RENEW) bin/vault-ddb operator migrate -config config/migrate.hcl
	$(MAKE) down
	$(MAKE) begin

backup:
	$(MAKE) renew
	$(MAKE) seal || true
	$(MAKE) seal2 || true
	cd backup && git-crypt unlock
	$(RENEW) bin/vault-ddb operator migrate -config config/backup-ddb.hcl
	$(RENEW) bin/vault-s3 operator migrate -config config/backup-s3.hcl
	cd backup && git add -u . && git commit -m backup
	cd backup && git-crypt lock
	$(MAKE) down
	$(MAKE) begin

renew:
	mkdir -p .aws
	touch .aws/credentials.tmp
	aws-okta write-to-credentials --assume-role-ttl=15m fogg-security .aws/credentials.tmp
	perl -pe 's{^\[.*}{[default]}' -i .aws/credentials.tmp
	mv -f .aws/credentials.tmp .aws/credentials

begin:
	$(MAKE) renew
	$(MAKE) recreate
	sleep 5
	cd backup && git-crypt unlock
	$(MAKE) root-login
	$(MAKE) root-login2
	cd backup && git-crypt lock

end:
	$(MAKE) renew
	$(MAKE) seal || true
	$(MAKE) seal2 || true
	$(MAKE) down 
	rm -f .aws/credentials

lock:
	git-crypt lock

root-login:
	@$(RENEW) bin/vault-ddb login "$(shell cat backup/.vault-root-token)"

seal:
	$(RENEW) bin/vault-ddb operator seal

root-login2:
	@$(RENEW) bin/vault-s3 login "$(shell cat backup/.vault-root-token)"

seal2:
	$(RENEW) bin/vault-s3 operator seal
