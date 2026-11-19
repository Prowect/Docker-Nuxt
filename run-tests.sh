#!/bin/sh
set -eu
IMAGE=${1:-local/prowect-nuxt:node26-arm64}
APP=${2:-}
PLATFORM=${PLATFORM:-linux/arm64}
EXPECTED_NODE_VERSION=${EXPECTED_NODE_VERSION:-v26.13.1}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
NAME=prowect-nuxt-test-$$
DERIVED=local/prowect-nuxt-test:$$
TEMP=$(mktemp -d)
cleanup() {
    docker rm -fv "$NAME" >/dev/null 2>&1 || true
    docker image rm "$DERIVED" >/dev/null 2>&1 || true
    rm -rf "$TEMP"
}
trap cleanup EXIT INT TERM
docker run --platform "$PLATFORM" --rm --network none \
    -e "EXPECTED_NODE_VERSION=$EXPECTED_NODE_VERSION" --entrypoint sh "$IMAGE" \
    -c 'test "$(node -v)" = "$EXPECTED_NODE_VERSION" && test "$(npm -v)" = 11.21.3 && ! command -v nginx'
mkdir -p "$TEMP/fixture/.output/server"
printf 'export default {}\n' > "$TEMP/fixture/nuxt.config.ts"
cat > "$TEMP/fixture/.output/server/index.mjs" <<'EOF'
import {createServer} from 'node:http';
createServer((request, response) => response.end('nuxt-runtime-ok')).listen(3000, '0.0.0.0');
EOF
docker run --platform "$PLATFORM" -d --network none --name "$NAME" -v "$TEMP/fixture:/app:ro" "$IMAGE" >/dev/null
READY=false
for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if docker exec "$NAME" node -e 'fetch("http://127.0.0.1:3000").then(r=>r.text()).then(t=>{if(t!=="nuxt-runtime-ok")process.exit(1)}).catch(()=>process.exit(1))'; then READY=true; break; fi
    sleep 1
done
[ "$READY" = true ]
docker rm -fv "$NAME" >/dev/null
if [ -n "$APP" ]; then
    test -f "$APP/package-lock.json"
    mkdir -p "$TEMP/context/app"
    tar --exclude='./.git' --exclude='./.env*' --exclude='./.npmrc' --exclude='./node_modules' --exclude='./.nuxt' --exclude='./.output' -C "$APP" -cf "$TEMP/app.tar" .
    tar -C "$TEMP/context/app" -xf "$TEMP/app.tar"
    cat > "$TEMP/context/Dockerfile" <<'EOF'
ARG BASE_IMAGE=local/prowect-nuxt:node26-arm64
FROM ${BASE_IMAGE} AS build
COPY app /app
RUN /main-entrypoint.sh build && test -s .output/server/index.mjs && node --check .output/server/index.mjs
RUN npm run test --if-present
FROM ${BASE_IMAGE}
COPY --from=build /app /app
EOF
    docker build --platform "$PLATFORM" --build-arg "BASE_IMAGE=$IMAGE" --tag "$DERIVED" "$TEMP/context"
    docker run --platform "$PLATFORM" -d --network none --name "$NAME" \
        -e NUXT_PUBLIC_APP_ENV=production \
        -e NUXT_PUBLIC_API_BASE=http://127.0.0.1:9/api \
        "$DERIVED" >/dev/null
    if ! docker exec -i \
        -e "SMOKE_ROUTES=${SMOKE_ROUTES:-/}" \
        -e "SMOKE_TEXT=${SMOKE_TEXT:-}" \
        -e "SMOKE_STATIC=${SMOKE_STATIC:-}" \
        "$NAME" node --input-type=module < "$SCRIPT_DIR/tests/http-smoke.mjs"; then
        docker logs "$NAME" >&2
        exit 1
    fi
    test "$(docker inspect "$NAME" --format '{{.State.Running}}')" = true
    docker restart "$NAME" >/dev/null
    docker exec -i -e "SMOKE_TEXT=${SMOKE_TEXT:-}" "$NAME" node --input-type=module < "$SCRIPT_DIR/tests/http-smoke.mjs"
fi
echo "PASS: $PLATFORM $EXPECTED_NODE_VERSION runtime, existing-output startup and optional application build/tests/HTTP/restart"
