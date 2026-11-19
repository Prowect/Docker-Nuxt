FROM node:26.13.1-alpine3.23@sha256:39d8c143e60e99ae98f014bebea1e72fc96d3c9bdf9504bc3a27af5c05bfa39f

LABEL org.opencontainers.image.title="Docker Nuxt by Prowect"
LABEL org.opencontainers.image.description="Docker image for Nuxt 4 applications"
LABEL org.opencontainers.image.authors="office@prowect.com"
LABEL org.opencontainers.image.source="https://github.com/Prowect/Docker-Nuxt"

RUN apk upgrade --no-cache \
    && npm install -g npm@11.21.3

WORKDIR /app

ENV NPM_CONFIG_LOGLEVEL=warn
ENV HOST=0.0.0.0

COPY entrypoint.sh /main-entrypoint.sh
RUN chmod +x /main-entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/main-entrypoint.sh"]
