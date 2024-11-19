SHELL := /bin/bash

PORT := 6301

CF_APP ?= notify-email-provider-stub
CF_ORG ?= govuk-notify

.PHONY: freeze-requirements
freeze-requirements: ## create static requirements.txt
	pip3 install --upgrade pip-tools
	python -c "from notifications_utils.version_tools import copy_config; copy_config()"
	pip-compile requirements.in

.PHONY: bump-utils
bump-utils:  # Bump notifications-utils package to latest version
	python -c "from notifications_utils.version_tools import upgrade_version; upgrade_version()"

.PHONY: bootstrap
bootstrap:
	pip install -r requirements.txt

.PHONY: run
run:
	$(if ${NOTIFICATION_QUEUE_PREFIX},,$(error Must specify NOTIFICATION_QUEUE_PREFIX))
	FLASK_DEBUG=true flask run -p ${PORT}

.PHONY: build-with-docker
build-with-docker:
	docker build -f docker/Dockerfile -t email-provider-stub .

.PHONY: run-with-docker
run-with-docker: build-with-docker
	$(if ${NOTIFICATION_QUEUE_PREFIX},,$(error Must specify NOTIFICATION_QUEUE_PREFIX))
	@docker run \
		-p ${PORT}:${PORT} \
		-e PORT=${PORT} \
		-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
		-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
		-e NOTIFICATION_QUEUE_PREFIX=${NOTIFICATION_QUEUE_PREFIX} \
		email-provider-stub
