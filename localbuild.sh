#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
_IMAGE_NAME="$(< IMAGE_NAME)"
_IMAGE_VERSION="$(< VERSION)"

cd "${SCRIPT_DIR}" || exit 1

# Create a parallel multi-platform builder
docker buildx create --name mybuilder --use
# Make "buildx" the default
docker buildx install
# Build for multiple platforms
docker build \
  --iidfile=.image-id \
  --platform linux/amd64,linux/arm64 \
  "--tag=${_IMAGE_NAME}:latest" \
  "--tag=${_IMAGE_NAME}:${_IMAGE_VERSION}" .
exit $?
