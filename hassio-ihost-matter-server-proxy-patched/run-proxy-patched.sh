#!/usr/bin/env bash
set -e

log_info() {
    echo "[$(date +%H:%M:%S)] INFO: $*"
}

log_warn() {
    echo "[$(date +%H:%M:%S)] WARNING: $*"
}

OPTIONS_FILE="/data/options.json"
PROXY_ENABLED="false"
PROXY_URL=""
NO_PROXY_VALUE="localhost,127.0.0.1,supervisor,homeassistant,core-matter-server,core_matter_server,172.30.0.0/16,192.168.0.0/16,192.168.10.0/24"

if [ -f "$OPTIONS_FILE" ]; then
    PROXY_ENABLED=$(jq -r '.proxy.enabled // false' "$OPTIONS_FILE" 2>/dev/null || echo "false")
    PROXY_URL=$(jq -r '.proxy.url // empty' "$OPTIONS_FILE" 2>/dev/null || true)
    NO_PROXY_VALUE=$(jq -r '.proxy.no_proxy // empty' "$OPTIONS_FILE" 2>/dev/null || echo "$NO_PROXY_VALUE")
fi

if [ -z "$NO_PROXY_VALUE" ] || [ "$NO_PROXY_VALUE" = "null" ]; then
    NO_PROXY_VALUE="localhost,127.0.0.1,supervisor,homeassistant,core-matter-server,core_matter_server,172.30.0.0/16,192.168.0.0/16,192.168.10.0/24"
fi

log_info "Matter Server proxy patched entrypoint"

if [ "$PROXY_ENABLED" = "true" ] && [ -n "$PROXY_URL" ] && [ "$PROXY_URL" != "null" ]; then
    export HTTP_PROXY="$PROXY_URL"
    export HTTPS_PROXY="$PROXY_URL"
    export ALL_PROXY="$PROXY_URL"
    export http_proxy="$PROXY_URL"
    export https_proxy="$PROXY_URL"
    export all_proxy="$PROXY_URL"
    export NO_PROXY="$NO_PROXY_VALUE"
    export no_proxy="$NO_PROXY_VALUE"

    log_info "Proxy enabled for Matter Server external requests"
    log_info "Proxy URL: $PROXY_URL"
    log_info "No proxy: $NO_PROXY_VALUE"
else
    unset HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy
    export NO_PROXY="$NO_PROXY_VALUE"
    export no_proxy="$NO_PROXY_VALUE"
    log_warn "Proxy disabled or proxy URL is empty; Matter Server will use direct internet access"
fi

if command -v python3 >/dev/null 2>&1; then
    log_info "Python version: $(python3 --version 2>/dev/null || true)"
fi

# Start original iHost Matter Server image entrypoint.
# The base image uses S6/init, so we preserve the original startup path.
if [ -x /init ]; then
    log_info "Starting original /init"
    exec /init
fi

log_warn "Original /init not found; trying common fallback commands"

if command -v matter-server >/dev/null 2>&1; then
    exec matter-server
fi

if command -v python3 >/dev/null 2>&1; then
    exec python3 -m matter_server.server
fi

log_warn "No known Matter Server start command found"
find / -maxdepth 3 -type f \( -name '*matter*' -o -name 'run' -o -name 'services.d' \) 2>/dev/null | sed 's#^#  #' || true
exit 1
