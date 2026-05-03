#!/usr/bin/env bashio
set -e

bashio::log.info "Patched eWeLink entrypoint: skipping core_mosquitto install/start checks"

bashio::log.info "os info: "
OS=$(bashio::os)
bashio::log.info "$OS"

BOARD=$(echo "$OS" | jq -r '.board')
bashio::log.info "Current Board: $BOARD"

if [ "$BOARD" != "ihost" ]; then
    bashio::log.error "Failed to start the add-on. Home Assistant must be running on iHost."
    bashio::exit.nok
fi

bashio::log.info "Node version: $(node --version)"
bashio::log.info "Npm version: $(npm --version)"
bashio::log.info "Current Add-on version is $(bashio::addon.version)"

MQTT_SERVER_CONFIG=$(bashio::config 'mqtt.server')
MQTT_USER_CONFIG=$(bashio::config 'mqtt.username')
MQTT_PASS_CONFIG=$(bashio::config 'mqtt.password')

if [ -z "$MQTT_SERVER_CONFIG" ] || [ "$MQTT_SERVER_CONFIG" = "null" ]; then
    MQTT_SERVER_CONFIG="mqtt://127.0.0.1:1883"
fi

export MQTT_SERVER="$MQTT_SERVER_CONFIG"
export MQTT_USER="$MQTT_USER_CONFIG"
export MQTT_PASS="$MQTT_PASS_CONFIG"
export IHOST_HARDWARE_VERSION="$(bashio::addon.version)"

bashio::log.info "Using MQTT server: ${MQTT_SERVER}"
bashio::log.info "Using MQTT user: ${MQTT_USER}"

cd /workspace
bashio::log.info "Working directory: $(pwd)"

if [ -f package.json ] && node -e "const p=require('./package.json'); process.exit(p.scripts && p.scripts.start ? 0 : 1)"; then
    bashio::log.info "Starting eWeLink application with: npm start"
    exec npm start
fi

if [ -f /workspace/src/index.js ]; then
    bashio::log.info "Starting eWeLink application with: node /workspace/src/index.js"
    exec node /workspace/src/index.js
fi

if [ -f /workspace/src/server.js ]; then
    bashio::log.info "Starting eWeLink application with: node /workspace/src/server.js"
    exec node /workspace/src/server.js
fi

if [ "$#" -gt 0 ]; then
    bashio::log.info "Starting eWeLink application with original CMD: $*"
    exec "$@"
fi

bashio::log.error "No known eWeLink start command found"
bashio::exit.nok
