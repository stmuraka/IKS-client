#!/usr/bin/env bash

set -eo pipefail

# Build the iks-client image

IMAGE_NAME="iks-client"
PLATFORM="linux/arm64" # Macbook Pro M1

docker pull alpine:latest
docker buildx build --platform ${PLATFORM} -t ${IMAGE_NAME} .
