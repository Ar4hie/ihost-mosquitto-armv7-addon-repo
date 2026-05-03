# iHost Mosquitto armv7 Add-on Repository

Custom Home Assistant add-on repository for Sonoff iHost / armv7.

This repository does not build Mosquitto. It reuses the existing Home Assistant Docker image:

```text
homeassistant/armv7-addon-mosquitto:6.5.2
```

The important part is that the add-on declares:

```yaml
services:
  - "mqtt:provide"
```

This allows other add-ons that request `mqtt:need` to see a valid MQTT service provider.

## Install

1. Create a new GitHub repository.
2. Upload these files preserving the folder structure.
3. Edit `repository.yaml` and `mosquitto/config.yaml`, replacing `YOUR_GITHUB_USER`.
4. In Home Assistant:
   - Settings → Add-ons → Add-on Store
   - Three dots → Repositories
   - Add the GitHub repository URL
5. Install **Mosquitto broker** from this custom repository.
6. Start it.
7. Check logs.
8. Then start iHost add-ons that require MQTT.

## Notes

Before installing, uninstall or disable broken official Mosquitto installations to avoid provider/port conflicts.
