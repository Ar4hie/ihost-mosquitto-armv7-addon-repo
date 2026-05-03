#!/usr/bin/env bash
set -e

log_info() {
    echo "[$(date +%H:%M:%S)] INFO: $*"
}

log_error() {
    echo "[$(date +%H:%M:%S)] ERROR: $*" >&2
}

log_info "Patched eWeLink entrypoint: skipping core_mosquitto install/start checks"

OPTIONS_FILE="/data/options.json"
MQTT_SERVER_CONFIG=""
MQTT_USER_CONFIG=""
MQTT_PASS_CONFIG=""

if [ -f "$OPTIONS_FILE" ]; then
    MQTT_SERVER_CONFIG=$(jq -r '.mqtt.server // empty' "$OPTIONS_FILE" 2>/dev/null || true)
    MQTT_USER_CONFIG=$(jq -r '.mqtt.username // empty' "$OPTIONS_FILE" 2>/dev/null || true)
    MQTT_PASS_CONFIG=$(jq -r '.mqtt.password // empty' "$OPTIONS_FILE" 2>/dev/null || true)
fi

if [ -z "$MQTT_SERVER_CONFIG" ] || [ "$MQTT_SERVER_CONFIG" = "null" ]; then
    MQTT_SERVER_CONFIG="mqtt://127.0.0.1:1883"
fi

export MQTT_SERVER="$MQTT_SERVER_CONFIG"
export MQTT_USER="$MQTT_USER_CONFIG"
export MQTT_PASS="$MQTT_PASS_CONFIG"
export IHOST_HARDWARE_VERSION="1.1.0-patched3"
export PATH="/workspace/node_modules/.bin:$PATH"

log_info "Node version: $(node --version 2>/dev/null || true)"
log_info "Npm version: $(npm --version 2>/dev/null || true)"
log_info "Using MQTT server: ${MQTT_SERVER}"
log_info "Using MQTT user: ${MQTT_USER}"

cd /workspace
log_info "Working directory: $(pwd)"

# Prefer already built application if it exists.
if [ -f /workspace/dist/app.js ]; then
    log_info "Starting eWeLink application with fastify dist/app.js"
    exec fastify start -l info -p 8325 -a 0.0.0.0 /workspace/dist/app.js
fi

# Avoid npm start first: original npm start runs npm run build, but the image lacks tsc.
if [ -f /workspace/src/server.js ]; then
    log_info "Starting eWeLink application with node /workspace/src/server.js"
    exec node /workspace/src/server.js
fi

if [ -f /workspace/src/index.js ]; then
    log_info "Starting eWeLink application with node /workspace/src/index.js"
    exec node /workspace/src/index.js
fi

if [ "$#" -gt 0 ]; then
    log_info "Starting eWeLink application with original CMD"
    exec "$@"
fi

log_error "No known eWeLink start command found"
exit 1
