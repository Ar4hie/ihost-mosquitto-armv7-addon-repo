# Upstream provenance

This add-on is derived from the armv7 Zigbee2MQTT work in:

- Repository: `gregzki/hassio-ihost-addon`
- Upstream implementation commit: `a6028bd319688f8760e12b0c187c2aecc38d5d45`
- Imported Zigbee2MQTT version: `2.12.1-1`
- Original project lineage: `iHost-Open-Source-Project/hassio-ihost-addon`
- Zigbee2MQTT application source: `Koenkk/zigbee2mqtt`

## Local changes

The Ar4hie variant:

- publishes its own GHCR image instead of referencing the Gregzki image;
- uses the unique slug `zigbee2mqtt_armv7`;
- keeps the old `zigbee2mqtt_patched_mqtt` add-on available for rollback;
- defaults to the Sonoff iHost built-in radio at `/dev/ttyS4` with `adapter: ember`;
- supports Supervisor MQTT service discovery and explicit MQTT settings;
- uses manual boot and experimental stage for the first validation release;
- uses a repository-specific tagged release workflow.

The MIT copyright and permission notice is retained in `LICENSE`.
