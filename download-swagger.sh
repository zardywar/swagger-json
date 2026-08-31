#!/bin/sh

set -e

echo "Downloading Swagger JSON..."

curl \
    --fail \
    --silent \
    --show-error \
    --location \
    --user "${SWAGGER_USERNAME}:${SWAGGER_PASSWORD}" \
    "${SWAGGER_URL}" \
    --output "${SWAGGER_JSON}"

echo "Swagger JSON downloaded successfully:"
echo "  ${SWAGGER_JSON}"