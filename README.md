# 🐳 Docker Nuxt

This Docker image provides everything you need to set up a Nuxt application. With this image you can start developing directly without any dependencies.

Following packages are included:

 - Node (18.15.0)
 - NPM

## Getting started

Actually, you only need to run the Docker image and you can start right away.

**docker-compose-dev.yml**

```yml
version: '3'

services:
    nuxt:
        image: prowect/nuxt
        command: "npm run dev"
        volumes:
            - "./src:/app"
        ports:
            - "3000:3000"
            - "24678:24678"
```

**docker-compose-production.yml**

```yml
version: '3'

services:
    nuxt:
        image: prowect/nuxt
        restart: unless-stopped
        ports:
            - "3000:3000"
```

## Production tips

For using this image in production we suggest: building your own Docker image, using this one as a base image.

```Dockerfile
# BUILD
FROM prowect/nuxt as build

# copy your nuxt files to /app
COPY ./src /app

# automatic magic builds your Nuxt application with dependencies, etc.
RUN /main-entrypoint.sh build

# BUNDLE
FROM prowect/nuxt

# copy pre-built files to the new container (to start even faster)
COPY --from=build /app /app
```

First step is building the Nuxt application. Usually this is done on startup of the image anyway, but for performance reasons we should fully build it and start the container already fully built.