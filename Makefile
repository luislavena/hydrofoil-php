VERSION ?= 8.5
REGISTRY ?= ghcr.io

DOCKERFILE := docker/${VERSION}/Dockerfile
IMAGE_NAME := ${REGISTRY}/luislavena/hydrofoil-php

TEST_DIR := docker/${VERSION}/test

GOSS_FILE := docker/${VERSION}/goss.yaml
export GOSS_FILE

.PHONY: test
test: build
	@if [ -d "${TEST_DIR}" ]; then \
	    IMAGE=${IMAGE_NAME}:${VERSION} vendor/brat -j 4 ${TEST_DIR}/*.brat; \
	elif [ -f "${GOSS_FILE}" ]; then \
	    dgoss run ${IMAGE_NAME}:${VERSION} sleep infinity; \
	else \
	    echo "No tests for ${VERSION}."; \
	fi

.PHONY: build
build: ${DOCKERFILE}
	docker build --progress=plain --pull -t ${IMAGE_NAME}:${VERSION} -f ${DOCKERFILE} .
