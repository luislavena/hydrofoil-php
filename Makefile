VERSION ?= 8.2
FLAVOR ?= debian
REGISTRY ?= ghcr.io

DOCKERFILE := docker/${VERSION}/${FLAVOR}/Dockerfile
GOSS_FILE := docker/${VERSION}/${FLAVOR}/goss.yaml
export GOSS_FILE

IMAGE_NAME := ${REGISTRY}/luislavena/hydrofoil-php
FULL_IMAGE := ${IMAGE_NAME}:${VERSION}

ifeq (${FLAVOR},alpine)
	FULL_IMAGE := ${FULL_IMAGE}-alpine
endif

.PHONY: test
test: build ${GOSS_FILE}
	dgoss run ${FULL_IMAGE} sleep infinity

.PHONY: build
build: ${DOCKERFILE}
	docker build --progress=plain --pull --load -t ${FULL_IMAGE} -f ${DOCKERFILE} .
