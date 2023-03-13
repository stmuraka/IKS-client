#!/usr/bin/env bash

# Build the iks-client image

IMAGE_NAME="iks-client"
docker build -t ${IMAGE_NAME} .
