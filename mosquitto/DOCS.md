# Mosquitto broker for iHost armv7

This add-on is a compatibility wrapper around Home Assistant Mosquitto `6.5.2`.

## Why

Newer official Mosquitto add-on releases no longer include `armv7`, while Sonoff iHost Home Assistant runs on `armv7`.

## Image

```text
homeassistant/armv7-addon-mosquitto:6.5.2
```

## MQTT service provider

This add-on declares:

```yaml
services:
  - "mqtt:provide"
```

That is the key line for other add-ons that require MQTT via Supervisor services.

## Default ports

- 1883/tcp — MQTT
- 1884/tcp — MQTT over WebSocket
- 8883/tcp — MQTT with SSL
- 8884/tcp — MQTT over WebSocket with SSL

## Configuration

Default config:

```yaml
logins: []
require_certificate: false
certfile: fullchain.pem
keyfile: privkey.pem
customize:
  active: false
  folder: mosquitto
```

You can leave `logins: []` if you want Home Assistant users to authenticate.
