# Changelog

## 2.12.1-1

- Added Zigbee2MQTT 2.12.1 for `armv7`.
- Added a dedicated image build from the official Zigbee2MQTT source release.
- Added defaults for the Sonoff iHost built-in Silicon Labs radio at `/dev/ttyS4` using the `ember` adapter.
- Added Home Assistant Supervisor MQTT service discovery with support for explicit MQTT overrides.
- Added a unique add-on slug so the older 2.6.3 rollback add-on can remain installed but stopped.
- Set the initial release to `experimental` with manual boot for safe migration testing.
