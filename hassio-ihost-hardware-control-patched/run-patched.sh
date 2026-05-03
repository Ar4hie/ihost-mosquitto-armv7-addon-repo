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

log_info "Patched iHost Hardware Control entrypoint: skipping core_mosquitto install/start checks"

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
    MQTT_SERVER_CONFIG="mqtt://2c914bdd-mosquitto:1883"
fi

MQTT_HOST_CONFIG=$(echo "$MQTT_SERVER_CONFIG" | sed -E 's#^mqtts?://([^/:]+).*#\1#')
MQTT_PORT_CONFIG=$(echo "$MQTT_SERVER_CONFIG" | sed -E 's#^mqtts?://[^/:]+:([0-9]+).*#\1#')
if [ "$MQTT_PORT_CONFIG" = "$MQTT_SERVER_CONFIG" ] || [ -z "$MQTT_PORT_CONFIG" ]; then
    MQTT_PORT_CONFIG="1883"
fi

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
export IHOST_HARDWARE_VERSION="1.1.3-patched1"

log_info "Node version: $(node --version 2>/dev/null || true)"
log_info "Npm version: $(npm --version 2>/dev/null || true)"
log_info "Using MQTT server: ${MQTT_SERVER}"
log_info "Using MQTT host: ${MQTT_HOST}"
log_info "Using MQTT port: ${MQTT_PORT}"
log_info "Using MQTT user: ${MQTT_USER}"

cd /app
log_info "Working directory: $(pwd)"

log_info "Waiting for MQTT broker authorization before starting Hardware Control app..."
for i in $(seq 1 30); do
    if node <<'NODE'
const mqtt = require('mqtt');
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

log_info "Starting iHost Hardware Control application..."
exec "$@"
