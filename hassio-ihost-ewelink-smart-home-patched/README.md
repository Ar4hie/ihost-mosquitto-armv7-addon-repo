# eWeLink Smart Home patched MQTT

This add-on entry reuses the official iHost eWeLink Smart Home Docker image, but removes the Supervisor `mqtt:need` declaration from the add-on manifest.

Why this exists:

- On Sonoff iHost / armv7, the official Home Assistant Mosquitto add-on is no longer installable.
- The original eWeLink Smart Home add-on tries to use/start `core_mosquitto` when MQTT settings are empty.
- This patched entry is intended to use an already running broker, for example the custom Mosquitto 6.5.2 armv7 add-on from this repository.

Default MQTT settings:

```yaml
mqtt:
  server: mqtt://127.0.0.1:1883
  username: mqtt_user
  password: ""
```

Before starting, set the password to the same password configured in the custom Mosquitto add-on.

If `mqtt://127.0.0.1:1883` does not work, try:

```yaml
mqtt:
  server: mqtt://2c914bdd-mosquitto:1883
```

or the actual host/container name shown by Home Assistant MQTT discovery.
