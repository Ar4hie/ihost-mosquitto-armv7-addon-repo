# Zigbee2MQTT armv7 for Sonoff iHost

This add-on packages Zigbee2MQTT 2.12.1 for Home Assistant Supervisor systems running on `armv7`, primarily Sonoff iHost.

## Important

This is a new add-on with the unique slug `zigbee2mqtt_armv7`. It does not replace the older `zigbee2mqtt_patched_mqtt` add-on automatically.

Never run both add-ons at the same time. They can compete for:

- the built-in iHost radio at `/dev/ttyS4`;
- the same MQTT base topic;
- the same data directory at `/config/zigbee2mqtt`.

The add-on is initially marked `experimental` and uses `boot: manual` so installing it cannot automatically take control of the Zigbee coordinator after a reboot.

## Default iHost radio configuration

```yaml
serial:
  port: /dev/ttyS4
  adapter: ember
  baudrate: 115200
  rtscts: false
```

The default data path is:

```text
/config/zigbee2mqtt
```

## MQTT

The add-on declares:

```yaml
services:
  - mqtt:need
```

It can consume the MQTT service provided by the Mosquitto armv7 add-on in this repository. Explicit `mqtt.server`, `mqtt.user`, and `mqtt.password` values remain supported and take priority over Supervisor service discovery.

## Safe migration from the older add-on

1. Create a full Home Assistant backup.
2. Copy `/config/zigbee2mqtt` to a separate backup location.
3. Record the current MQTT and serial settings.
4. Install this add-on, but do not start it yet.
5. Stop `Zigbee2MQTT patched MQTT 2.6.3-1`.
6. Disable automatic startup for the old add-on.
7. Start this add-on and inspect its log.
8. Confirm that all devices, groups, bindings, automations, and MQTT entities remain available.
9. Keep the old add-on installed but stopped until the new version has operated reliably for several days.

If rollback is required, stop this add-on before starting the old one.

## Release image

The add-on expects this image:

```text
ghcr.io/ar4hie/hassio-ihost-zigbee2mqtt-armv7:2.12.1-1
```

The image is built from the official Zigbee2MQTT source release by the repository GitHub Actions workflow.
