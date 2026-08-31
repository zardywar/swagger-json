FROM swaggerapi/swagger-ui:latest

USER root

RUN apk add --no-cache curl jq

COPY entrypoint.sh /entrypoint-custom.sh

RUN chmod +x /entrypoint-custom.sh

ENTRYPOINT ["/entrypoint-custom.sh"]