VERSION ?= 8.0
REGISTRY ?= ghcr.io

DOCKERFILE := docker/${VERSION}/Dockerfile
IMAGE_NAME := ${REGISTRY}/luislavena/hydrofoil-php

GOSS_FILE := docker/${VERSION}/goss.yaml
export GOSS_FILE

.PHONY: test
test: build ${GOSS_FILE}
	dgoss run ${IMAGE_NAME}:${VERSION} sleep infinity

.PHONY: build
build: ${DOCKERFILE}
	docker build --progress=plain --pull -t ${IMAGE_NAME}:${VERSION} -f ${DOCKERFILE} .
