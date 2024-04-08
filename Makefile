SHELL := /bin/bash

PORT := 6301

CF_APP ?= notify-email-provider-stub
CF_ORG ?= govuk-notify

.PHONY: bootstrap
bootstrap:
	pip install -r requirements_for_test.txt

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
