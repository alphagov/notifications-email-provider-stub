SHELL := /bin/bash

PORT := 6301

CF_APP ?= notify-email-provider-stub
CF_ORG ?= govuk-notify
CF_MANIFEST_PATH ?= /tmp/manifest.yml

NOTIFY_CREDENTIALS ?= ~/.notify-credentials

.PHONY: bootstrap
bootstrap:
	pip install -r requirements_for_test.txt

.PHONY: run
run:
	$(if ${NOTIFICATION_QUEUE_PREFIX},,$(error Must specify NOTIFICATION_QUEUE_PREFIX))
	FLASK_DEBUG=true flask run -p 6301

.PHONY: preview
preview:
	$(eval export CF_SPACE=preview)
	@true

.PHONY: staging
staging:
	$(eval export CF_SPACE=staging)
	@true

.PHONY: generate-manifest
generate-manifest:
	$(if ${CF_SPACE},,$(error Must specify CF_SPACE))
	$(if $(shell which gpg2), $(eval export GPG=gpg2), $(eval export GPG=gpg))
	$(if ${GPG_PASSPHRASE_TXT}, $(eval export DECRYPT_CMD=echo -n $$$${GPG_PASSPHRASE_TXT} | ${GPG} --quiet --batch --passphrase-fd 0 --pinentry-mode loopback -d), $(eval export DECRYPT_CMD=${GPG} --quiet --batch -d))

	@jinja2 --strict manifest.yml.j2 \
	    -D environment=${CF_SPACE} \
	    --format=yaml \
	    <(${DECRYPT_CMD} ${NOTIFY_CREDENTIALS}/credentials/${CF_SPACE}/paas/environment-variables.gpg) 2>&1

.PHONY: cf-deploy
cf-deploy:
	$(if ${CF_SPACE},,$(error Must specify CF_SPACE))
	cf target -o ${CF_ORG} -s ${CF_SPACE}
	@cf app --guid ${CF_APP} || exit 1

	# cancel any existing deploys to ensure we can apply manifest (if a deploy is in progress you'll see ScaleDisabledDuringDeployment)
	cf cancel-deployment ${CF_APP} || true

	# generate manifest (including secrets) and write it to CF_MANIFEST_PATH (in /tmp/)
	make -s CF_APP=${CF_APP} generate-manifest > ${CF_MANIFEST_PATH}

	# fails after 15 mins if deploy doesn't work
	# reads manifest from CF_MANIFEST_PATH
	CF_STARTUP_TIMEOUT=15 cf push ${CF_APP} --strategy=rolling -f ${CF_MANIFEST_PATH}
	# delete old manifest file
	rm ${CF_MANIFEST_PATH}
