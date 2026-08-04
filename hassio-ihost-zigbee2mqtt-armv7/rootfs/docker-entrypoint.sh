#!/usr/bin/env bashio

bashio::log.info "Preparing Zigbee2MQTT armv7..."
bashio::config.require 'data_path'

if bashio::config.true 'socat.enabled'; then
    SOCAT_MASTER="$(bashio::config 'socat.master')"
    SOCAT_SLAVE="$(bashio::config 'socat.slave')"
    SOCAT_OPTIONS="$(bashio::config 'socat.options')"
    DATA_PATH="$(bashio::config 'data_path')"

    if [[ -z "${SOCAT_MASTER}" ]]; then
        bashio::exit.nok "Socat is enabled but socat.master is empty"
    fi
    if [[ -z "${SOCAT_SLAVE}" ]]; then
        bashio::exit.nok "Socat is enabled but socat.slave is empty"
    fi

    bashio::log.info "Starting socat"
    if bashio::config.true 'socat.log'; then
        socat ${SOCAT_OPTIONS} "${SOCAT_MASTER}" "${SOCAT_SLAVE}" \
            >>"${DATA_PATH}/socat.log" 2>&1 &
    else
        socat ${SOCAT_OPTIONS} "${SOCAT_MASTER}" "${SOCAT_SLAVE}" &
    fi
else
    bashio::log.info "Socat is disabled"
fi

export ZIGBEE2MQTT_DATA="$(bashio::config 'data_path')"
mkdir -p "${ZIGBEE2MQTT_DATA}" || bashio::exit.nok "Unable to create ${ZIGBEE2MQTT_DATA}"

export NODE_PATH=/app/node_modules
export NODE_ENV=production
export ZIGBEE2MQTT_CONFIG_FRONTEND_ENABLED=true
export ZIGBEE2MQTT_CONFIG_FRONTEND_PORT=8099
export ZIGBEE2MQTT_CONFIG_HOMEASSISTANT_ENABLED=true
export Z2M_ONBOARD_URL=http://0.0.0.0:8099
export TZ="$(bashio::supervisor.timezone)"

if bashio::config.has_value 'watchdog'; then
    export Z2M_WATCHDOG="$(bashio::config 'watchdog')"
    bashio::log.info "Zigbee2MQTT watchdog is enabled"
fi

if bashio::config.true 'force_onboarding'; then
    export Z2M_ONBOARD_FORCE_RUN=1
    bashio::log.warning "Forced onboarding is enabled"
fi

if bashio::config.true 'disable_tuya_default_response'; then
    export DISABLE_TUYA_DEFAULT_RESPONSE=true
    bashio::log.info "Tuya default responses are disabled"
fi

export_config_group() {
    local key="${1}"
    local subkey

    if bashio::config.is_empty "${key}"; then
        return
    fi

    while IFS= read -r subkey; do
        export "ZIGBEE2MQTT_CONFIG_$(bashio::string.upper "${key}")_$(bashio::string.upper "${subkey}")=$(bashio::config "${key}.${subkey}")"
    done < <(bashio::jq "$(bashio::config "${key}")" 'keys[]')
}

export_config_group mqtt
export_config_group serial

# Prefer explicit MQTT settings. If mqtt.server is not configured, consume the
# MQTT service published to Supervisor by the Mosquitto armv7 add-on.
if ! bashio::config.has_value 'mqtt.server' && bashio::var.has_value "$(bashio::services 'mqtt')"; then
    if bashio::var.true "$(bashio::services 'mqtt' 'ssl')"; then
        export ZIGBEE2MQTT_CONFIG_MQTT_SERVER="mqtts://$(bashio::services 'mqtt' 'host'):$(bashio::services 'mqtt' 'port')"
    else
        export ZIGBEE2MQTT_CONFIG_MQTT_SERVER="mqtt://$(bashio::services 'mqtt' 'host'):$(bashio::services 'mqtt' 'port')"
    fi

    if ! bashio::config.has_value 'mqtt.user'; then
        export ZIGBEE2MQTT_CONFIG_MQTT_USER="$(bashio::services 'mqtt' 'username')"
    fi
    if ! bashio::config.has_value 'mqtt.password'; then
        export ZIGBEE2MQTT_CONFIG_MQTT_PASSWORD="$(bashio::services 'mqtt' 'password')"
    fi

    bashio::log.info "Using the MQTT service provided by Home Assistant Supervisor"
else
    bashio::log.info "Using explicitly configured MQTT settings"
fi

bashio::log.info "Starting Zigbee2MQTT..."
cd /app
exec node index.js
