FROM node:18.15.0-alpine

LABEL org.opencontainers.image.title="Docker Nuxt by Prowect"
LABEL org.opencontainers.image.description="Docker image for Nuxt applications"
LABEL org.opencontainers.image.authors="office@prowect.com"
LABEL org.opencontainers.image.source="https://github.com/Prowect/Docker-Nuxt"

RUN npm install -g npm@9.6.2

WORKDIR /app

ENV NPM_CONFIG_LOGLEVEL warn
ENV HOST 0.0.0.0

ADD entrypoint.sh /main-entrypoint.sh
RUN chmod +x /main-entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/main-entrypoint.sh"]