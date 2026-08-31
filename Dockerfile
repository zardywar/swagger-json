FROM swaggerapi/swagger-ui:latest

USER root

RUN apk add --no-cache curl

COPY download-swagger.sh /docker-entrypoint.d/05-download-swagger.sh

RUN chmod +x /docker-entrypoint.d/05-download-swagger.sh