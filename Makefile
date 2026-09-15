VERSION ?= 8.5
REGISTRY ?= ghcr.io

DOCKERFILE := docker/${VERSION}/Dockerfile
IMAGE_NAME := ${REGISTRY}/luislavena/hydrofoil-php

GOSS_FILE := docker/${VERSION}/goss.yaml
export GOSS_FILE

.PHONY: test
test: build
	@if [ -f "${GOSS_FILE}" ]; then \
	    dgoss run ${IMAGE_NAME}:${VERSION} sleep infinity; \
	else \
	    echo "No goss file for ${VERSION}. The build-time checks already ran."; \
	fi

.PHONY: build
build: ${DOCKERFILE}
	docker build --progress=plain --pull -t ${IMAGE_NAME}:${VERSION} -f ${DOCKERFILE} .
