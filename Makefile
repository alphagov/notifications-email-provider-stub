SHELL := /bin/bash

PORT := 6301

NOTIFY_CREDENTIALS ?= ~/.notify-credentials

.PHONY: bootstrap
bootstrap:
	pip install -r requirements_for_test.txt

.PHONY: run
run:
	$(if ${NOTIFICATION_QUEUE_PREFIX},,$(error Must specify NOTIFICATION_QUEUE_PREFIX))
	gunicorn --bind 0.0.0.0:${PORT} --worker-class=eventlet --workers=2 wsgi:app

.PHONY: preview
preview:
	$(eval export CF_SPACE=preview)
	cf target -s ${CF_SPACE}

.PHONY: staging
staging:
	$(eval export CF_SPACE=staging)
	cf target -s ${CF_SPACE}

.PHONY: generate-manifest
generate-manifest:
	$(if ${CF_SPACE},,$(error Must specify CF_SPACE))
	$(if $(shell which gpg2), $(eval export GPG=gpg2), $(eval export GPG=gpg))
	$(if ${GPG_PASSPHRASE_TXT}, $(eval export DECRYPT_CMD=echo -n $$$${GPG_PASSPHRASE_TXT} | ${GPG} --quiet --batch --passphrase-fd 0 --pinentry-mode loopback -d), $(eval export DECRYPT_CMD=${GPG} --quiet --batch -d))
	@jinja2 --strict manifest.yml.j2 \
		-D CF_SPACE=${CF_SPACE} \
	    --format=yaml \
	    <(${DECRYPT_CMD} ${NOTIFY_CREDENTIALS}/credentials/${CF_SPACE}/paas/environment-variables.gpg) 2>&1

.PHONY: cf-push
cf-push:
	$(if ${CF_SPACE},,$(error Must specify CF_SPACE))
	cf push -f <(make -s generate-manifest)
