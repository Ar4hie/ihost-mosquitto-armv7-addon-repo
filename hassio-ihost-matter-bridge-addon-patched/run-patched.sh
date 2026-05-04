#!/usr/bin/env bash
set -e

log_info() {
    echo "[$(date +%H:%M:%S)] INFO: $*"
}

log_warn() {
    echo "[$(date +%H:%M:%S)] WARNING: $*"
}

log_error() {
    echo "[$(date +%H:%M:%S)] ERROR: $*" >&2
}

log_info "Patched Matter Bridge entrypoint: skipping core_mosquitto service dependency"

OPTIONS_FILE="/data/options.json"
MQTT_SERVER_CONFIG=""
MQTT_USER_CONFIG=""
MQTT_PASS_CONFIG=""
LOG_LEVEL_CONFIG="Info"

if [ -f "$OPTIONS_FILE" ]; then
    MQTT_SERVER_CONFIG=$(jq -r '.mqtt.server // empty' "$OPTIONS_FILE" 2>/dev/null || true)
    MQTT_USER_CONFIG=$(jq -r '.mqtt.username // empty' "$OPTIONS_FILE" 2>/dev/null || true)
    MQTT_PASS_CONFIG=$(jq -r '.mqtt.password // empty' "$OPTIONS_FILE" 2>/dev/null || true)
    LOG_LEVEL_CONFIG=$(jq -r '.log_level // "Info"' "$OPTIONS_FILE" 2>/dev/null || echo "Info")
fi

if [ -z "$MQTT_SERVER_CONFIG" ] || [ "$MQTT_SERVER_CONFIG" = "null" ]; then
    MQTT_SERVER_CONFIG="mqtt://2c914bdd-mosquitto:1883"
fi

if [ -z "$MQTT_USER_CONFIG" ] || [ "$MQTT_USER_CONFIG" = "null" ]; then
    MQTT_USER_CONFIG="mqtt_user"
fi

if [ -z "$MQTT_PASS_CONFIG" ] || [ "$MQTT_PASS_CONFIG" = "null" ]; then
    MQTT_PASS_CONFIG="mqtt123456"
fi

MQTT_HOST_CONFIG=$(echo "$MQTT_SERVER_CONFIG" | sed -E 's#^mqtts?://([^/:]+).*#\1#')
MQTT_PORT_CONFIG=$(echo "$MQTT_SERVER_CONFIG" | sed -E 's#^mqtts?://[^/:]+:([0-9]+).*#\1#')
if [ "$MQTT_PORT_CONFIG" = "$MQTT_SERVER_CONFIG" ] || [ -z "$MQTT_PORT_CONFIG" ]; then
    MQTT_PORT_CONFIG="1883"
fi

# Export several aliases because the upstream app is prebuilt and may use different env names.
export LOG_LEVEL="$LOG_LEVEL_CONFIG"
export MQTT_SERVER="$MQTT_SERVER_CONFIG"
export MQTT_URL="$MQTT_SERVER_CONFIG"
export MQTT_BROKER="$MQTT_SERVER_CONFIG"
export MQTT_HOST="$MQTT_HOST_CONFIG"
export MQTT_PORT="$MQTT_PORT_CONFIG"
export MQTT_USER="$MQTT_USER_CONFIG"
export MQTT_PASS="$MQTT_PASS_CONFIG"
export MQTT_USERNAME="$MQTT_USER_CONFIG"
export MQTT_PASSWORD="$MQTT_PASS_CONFIG"
export mqtt_server="$MQTT_SERVER_CONFIG"
export mqtt_username="$MQTT_USER_CONFIG"
export mqtt_password="$MQTT_PASS_CONFIG"
export PATH="/workspace/node_modules/.bin:/app/node_modules/.bin:$PATH"

log_info "Node version: $(node --version 2>/dev/null || true)"
log_info "Npm version: $(npm --version 2>/dev/null || true)"
log_info "Using MQTT server: ${MQTT_SERVER}"
log_info "Using MQTT host: ${MQTT_HOST}"
log_info "Using MQTT port: ${MQTT_PORT}"
log_info "Using MQTT user: ${MQTT_USER}"
log_info "Log level: ${LOG_LEVEL}"

if [ -d /workspace ]; then
    cd /workspace
elif [ -d /app ]; then
    cd /app
else
    cd /
fi

log_info "Working directory: $(pwd)"

log_info "Waiting for MQTT broker authorization before starting Matter Bridge app..."
for i in $(seq 1 30); do
    if node <<'NODE'
let mqtt;
try {
  mqtt = require('mqtt');
} catch (err) {
  console.error('Node mqtt module is not available:', err && err.message ? err.message : String(err));
  process.exit(3);
}
const url = process.env.MQTT_SERVER || 'mqtt://2c914bdd-mosquitto:1883';
const username = process.env.MQTT_USER || process.env.MQTT_USERNAME || '';
const password = process.env.MQTT_PASS || process.env.MQTT_PASSWORD || '';
const client = mqtt.connect(url, { username, password, connectTimeout: 3000, reconnectPeriod: 0 });
const timer = setTimeout(() => {
  try { client.end(true); } catch (_) {}
  process.exit(2);
}, 4000);
client.on('connect', () => {
  clearTimeout(timer);
  client.end(true, () => process.exit(0));
});
client.on('error', (err) => {
  clearTimeout(timer);
  try { client.end(true); } catch (_) {}
  console.error(err && err.message ? err.message : String(err));
  process.exit(1);
});
NODE
    then
        log_info "MQTT broker authorization OK"
        break
    fi

    if [ "$i" -eq 30 ]; then
        log_error "MQTT broker authorization failed after 30 attempts"
        exit 1
    fi

    log_warn "MQTT broker not ready or authorization failed, retry ${i}/30"
    sleep 2
done

# Try common start points used by iHost Node.js add-ons.
if [ -f /workspace/dist/app.js ]; then
    log_info "Starting Matter Bridge application with fastify /workspace/dist/app.js"
    exec fastify start -l info -p 3030 -a 0.0.0.0 /workspace/dist/app.js
fi

if [ -f /workspace/dist/index.js ]; then
    log_info "Starting Matter Bridge application with node /workspace/dist/index.js"
    exec node /workspace/dist/index.js
fi

if [ -f /workspace/src/server.js ]; then
    log_info "Starting Matter Bridge application with node /workspace/src/server.js"
    exec node /workspace/src/server.js
fi

if [ -f /workspace/src/index.js ]; then
    log_info "Starting Matter Bridge application with node /workspace/src/index.js"
    exec node /workspace/src/index.js
fi

if [ -f /workspace/server.js ]; then
    log_info "Starting Matter Bridge application with node /workspace/server.js"
    exec node /workspace/server.js
fi

if [ -f /workspace/index.js ]; then
    log_info "Starting Matter Bridge application with node /workspace/index.js"
    exec node /workspace/index.js
fi

if [ -f /app/dist/app.js ]; then
    log_info "Starting Matter Bridge application with fastify /app/dist/app.js"
    exec fastify start -l info -p 3030 -a 0.0.0.0 /app/dist/app.js
fi

if [ -f /app/dist/index.js ]; then
    log_info "Starting Matter Bridge application with node /app/dist/index.js"
    exec node /app/dist/index.js
fi

if [ -f /app/src/server.js ]; then
    log_info "Starting Matter Bridge application with node /app/src/server.js"
    exec node /app/src/server.js
fi

if [ -f /app/src/index.js ]; then
    log_info "Starting Matter Bridge application with node /app/src/index.js"
    exec node /app/src/index.js
fi

if [ "$#" -gt 0 ]; then
    log_info "Starting Matter Bridge application with original CMD"
    exec "$@"
fi

log_error "No known Matter Bridge start command found"
log_info "Directory listing for diagnostics:"
find /workspace /app -maxdepth 4 -type f 2>/dev/null | sed 's#^#  #' || true
exit 1
