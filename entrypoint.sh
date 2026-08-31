#!/bin/sh

set -e

echo "========================================"
echo "Swagger UI Starting"
echo "========================================"

echo "Downloading Swagger JSON..."
echo "URL: ${SWAGGER_URL}"

curl \
    --fail \
    --silent \
    --show-error \
    --location \
    --user "${SWAGGER_USERNAME}:${SWAGGER_PASSWORD}" \
    "${SWAGGER_URL}" \
    --output /usr/share/nginx/html/swagger.json

echo "Swagger JSON downloaded successfully"

# Validasi JSON
if ! jq empty /usr/share/nginx/html/swagger.json > /dev/null 2>&1; then
    echo "ERROR: Swagger JSON is invalid"
    exit 1
fi

echo "Swagger JSON is valid"

echo "Adding Swagger server..."

jq \
    --arg url "${SWAGGER_SERVER}" \
    --arg description "${SWAGGER_SERVER_DESCRIPTION}" \
    '.servers = [
        {
            "url": $url,
            "description": $description
        }
    ]' \
    /usr/share/nginx/html/swagger.json \
    > /tmp/swagger.json

mv /tmp/swagger.json /usr/share/nginx/html/swagger.json

echo "Swagger server configuration:"
jq '.servers' /usr/share/nginx/html/swagger.json

echo "========================================"
echo "Configuring Swagger UI"
echo "========================================"

# Swagger UI config
cat > /usr/share/nginx/html/swagger-initializer.js <<EOF
window.onload = function() {
  window.ui = SwaggerUIBundle({
    url: "/swagger.json",
    dom_id: '#swagger-ui',
    deepLinking: true,
    presets: [
      SwaggerUIBundle.presets.apis,
      SwaggerUIStandalonePreset
    ],
    plugins: [
      SwaggerUIBundle.plugins.DownloadUrl
    ],
    layout: "StandaloneLayout"
  });
};
EOF

echo "Swagger UI configuration created"

echo "========================================"
echo "Starting nginx"
echo "========================================"

exec nginx -g "daemon off;"