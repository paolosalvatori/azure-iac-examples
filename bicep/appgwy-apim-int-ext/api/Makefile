VERSION := $(shell git rev-parse --short HEAD)
BUILD_DATE := $(shell date -R)
NAME := $(shell basename `git rev-parse --show-toplevel`)
VENDOR := $(shell whoami)
SEMVER := 0.1.0
ENVIRONMENT := dev
TAG := ${ENVIRONMENT}-${SEMVER}-${VERSION}

print:
	@echo VERSION=${VERSION}
	@echo SEMVER=${SEMVER}
	@echo BUILD_DATE=${BUILD_DATE}
	@echo NAME=${NAME}
	@echo VENDOR=${VENDOR}
build:
	docker build \
	-t belstarr/todo-api:${TAG} \
	--build-arg VERSION="${TAG}" \
	--build-arg SEMVER="${SEMVER}" \
	--build-arg BUILD_DATE="${BUILD_DATE}" \
	--build-arg NAME="${NAME}" \
	--build-arg VENDOR="${VENDOR}" .

push:
	docker push belstarr/todo-api:${TAG}

run:
	docker run \
	-d \
	-p 80:8080 \
	belstarr/todo-api:${TAG}
