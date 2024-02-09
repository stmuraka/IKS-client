#!/usr/bin/env bash

set -eo pipefail

# Build the iks-client image

IMAGE_NAME="iks-client"
docker pull alpine:latest
docker build -t ${IMAGE_NAME} .
