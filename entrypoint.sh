#!/bin/sh

set -e

echo "========================================"
echo "Swagger UI Starting"
echo "========================================"

# ============================================================
# Environment
# ============================================================

if [ -z "$SWAGGER_URL" ]; then
    echo "ERROR: SWAGGER_URL is not configured"
    exit 1
fi

if [ -z "$SWAGGER_USERNAME" ]; then
    echo "ERROR: SWAGGER_USERNAME is not configured"
    exit 1
fi

if [ -z "$SWAGGER_PASSWORD" ]; then
    echo "ERROR: SWAGGER_PASSWORD is not configured"
    exit 1
fi

echo ""
echo "Environment configuration OK"

# ============================================================
# Download Swagger JSON
# ============================================================

echo ""
echo "========================================"
echo "Downloading Swagger JSON"
echo "========================================"

echo "URL: $SWAGGER_URL"

curl -fsSL \
    -u "${SWAGGER_USERNAME}:${SWAGGER_PASSWORD}" \
    "$SWAGGER_URL" \
    -o /usr/share/nginx/html/swagger.json

echo "Swagger JSON downloaded successfully"

# ============================================================
# Validate JSON
# ============================================================

echo ""
echo "Validating Swagger JSON..."

if ! jq empty \
    /usr/share/nginx/html/swagger.json \
    > /dev/null 2>&1
then
    echo "ERROR: Swagger JSON is invalid"
    exit 1
fi

echo "Swagger JSON is valid"

# ============================================================
# Add Swagger Server
# ============================================================

if [ -n "$SWAGGER_SERVER" ]; then

    echo ""
    echo "========================================"
    echo "Adding Swagger Server"
    echo "========================================"

    echo "URL         : $SWAGGER_SERVER"
    echo "Description : $SWAGGER_SERVER_DESCRIPTION"

    jq \
        --arg url "$SWAGGER_SERVER" \
        --arg description "$SWAGGER_SERVER_DESCRIPTION" \
        '
        .servers = [
            {
                "url": $url,
                "description": $description
            }
        ]
        ' \
        /usr/share/nginx/html/swagger.json \
        > /tmp/swagger.json

    mv \
        /tmp/swagger.json \
        /usr/share/nginx/html/swagger.json

    echo ""
    echo "Swagger server configuration:"

    jq '.servers' \
        /usr/share/nginx/html/swagger.json

fi

# ============================================================
# Add BasicAuth Security Scheme
# ============================================================

echo ""
echo "========================================"
echo "Adding BasicAuth Security Scheme"
echo "========================================"

jq '
    .components = (.components // {}) |

    .components.securitySchemes =
        (.components.securitySchemes // {}) |

    .components.securitySchemes.BasicAuth = {
        "type": "http",
        "scheme": "basic"
    }
' \
    /usr/share/nginx/html/swagger.json \
    > /tmp/swagger.json

mv \
    /tmp/swagger.json \
    /usr/share/nginx/html/swagger.json

echo "BasicAuth security scheme added"

# ============================================================
# Add BasicAuth + APIKeyHeader to EVERY API operation
# ============================================================

echo ""
echo "========================================"
echo "Adding Security to Every API Operation"
echo "========================================"

jq '
    .paths |= with_entries(

        .value |= with_entries(

            if (
                .key == "get"
                or .key == "post"
                or .key == "put"
                or .key == "patch"
                or .key == "delete"
                or .key == "options"
                or .key == "head"
                or .key == "trace"
            )

            then

                .value.security = [
                    {
                        "APIKeyHeader": [],
                        "BasicAuth": []
                    }
                ]

            else

                .
            end
        )
    )
' \
    /usr/share/nginx/html/swagger.json \
    > /tmp/swagger.json

mv \
    /tmp/swagger.json \
    /usr/share/nginx/html/swagger.json

echo "Security added to every API operation"

# ============================================================
# Set Global Security
# ============================================================

jq '
    .security = [
        {
            "APIKeyHeader": [],
            "BasicAuth": []
        }
    ]
' \
    /usr/share/nginx/html/swagger.json \
    > /tmp/swagger.json

mv \
    /tmp/swagger.json \
    /usr/share/nginx/html/swagger.json

# ============================================================
# Show Security Schemes
# ============================================================

echo ""
echo "========================================"
echo "Security Schemes"
echo "========================================"

jq \
    '.components.securitySchemes' \
    /usr/share/nginx/html/swagger.json

# ============================================================
# Show Servers
# ============================================================

echo ""
echo "========================================"
echo "Servers"
echo "========================================"

jq \
    '.servers' \
    /usr/share/nginx/html/swagger.json

# ============================================================
# Count API Operations
# ============================================================

echo ""
echo "========================================"
echo "API Operations"
echo "========================================"

jq '
    [
        .paths[]
        | to_entries[]
        | select(
            .key == "get"
            or .key == "post"
            or .key == "put"
            or .key == "patch"
            or .key == "delete"
            or .key == "options"
            or .key == "head"
            or .key == "trace"
        )
    ]
    | length
' \
    /usr/share/nginx/html/swagger.json \
    | xargs echo "Total API operations:"
    
# ============================================================
# Configure Swagger UI
# ============================================================

echo ""
echo "========================================"
echo "Configuring Swagger UI"
echo "========================================"

unset SWAGGER_JSON
unset SWAGGER_JSON_URL
unset URL

cat > /usr/share/nginx/html/swagger-initializer.js <<EOF
window.onload = function() {
  window.ui = SwaggerUIBundle({
    url: "swagger.json",
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

echo "Swagger UI configured to use swagger.json"

# ============================================================
# Start Swagger UI
# ============================================================

echo ""
echo "========================================"
echo "Starting Swagger UI"
echo "========================================"

exec /docker-entrypoint.sh nginx -g "daemon off;"