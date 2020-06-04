SHELL := /bin/bash

PORT := 6301

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
	@sed -e "s/{{CF_SPACE}}/${CF_SPACE}/" manifest.yml.tpl

.PHONY: cf-push
cf-push:
	$(if ${CF_SPACE},,$(error Must specify CF_SPACE))
	cf push -f <(make -s generate-manifest)
