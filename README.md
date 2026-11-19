# 🐳 Docker Nuxt

This Docker image provides everything you need to set up a Nuxt application. With this image you can start developing directly without any dependencies.

Following packages are included:

 - Node (26.13.1 LTS)
 - NPM (11.21.3)

This image uses Node 26 LTS with a pinned image digest and retains Alpine 3.23
and npm 11. It contains no NGINX. Existing application dependencies are not upgraded.

## Compatibility tests

Build and test each target architecture explicitly:

```sh
docker build --platform linux/arm64 -t local/prowect-nuxt:node26-arm64 .
PLATFORM=linux/arm64 sh ./run-tests.sh local/prowect-nuxt:node26-arm64 /path/to/nuxt-app

docker build --platform linux/amd64 -t local/prowect-nuxt:node26-amd64 .
PLATFORM=linux/amd64 sh ./run-tests.sh local/prowect-nuxt:node26-amd64 /path/to/nuxt-app
```

The optional application directory must contain a package-lock.json. Tests copy
the source without environment files or existing build output, build through the
image entrypoint, run the application's test script if present, and check SSR,
JavaScript/CSS assets, HTTP 404 and restart. Runtime containers have no network
access to external services. Test containers and derived images are removed.
Use `SMOKE_ROUTES='/ /login /register'`, `SMOKE_TEXT=Allsona` and
`SMOKE_STATIC=/images/allsona/logo.svg` for application-specific checks.
These smoke tests do not exercise authenticated backend workflows or browser hydration.

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
