# iHost / armv7 Home Assistant add-ons

**English description is provided first. Russian description is available below.**  
**Описание на русском языке находится ниже после английской версии.**

---

# English

This repository was created to restore and extend the useful life of **Sonoff iHost running Home Assistant on armv7**.

The main problem: some official Home Assistant add-ons are no longer published for `armv7`. Because of this, iHost and other armv7-based Home Assistant Supervisor systems may lose access to add-ons that previously worked. The most critical case is MQTT: the official `core_mosquitto` add-on is no longer available for `armv7`, while several iHost add-ons still require MQTT through:

```yaml
services:
  - "mqtt:need"
```

This repository solves two practical problems:

1. It provides a working **Mosquitto broker for armv7** with `mqtt:provide`.
2. It provides patched or pinned add-ons for Sonoff iHost and other Home Assistant systems running on `armv7`.

The project is mainly intended for **Sonoff iHost / HA OS for iHost / board ihost / armv7**, but some add-ons may also be useful for other `armv7` Home Assistant Supervisor devices.

---

## Main component: Mosquitto broker for armv7

Folder:

```text
mosquitto/
```

It uses the existing official Home Assistant Docker image:

```text
homeassistant/armv7-addon-mosquitto:6.5.2
```

The important part is that this add-on declares itself as an MQTT service provider:

```yaml
services:
  - "mqtt:provide"
```

This allows Home Assistant Supervisor to see this broker as an available MQTT provider for other add-ons.

MQTT settings used during testing on iHost:

```yaml
server: mqtt://2c914bdd-mosquitto:1883
username: mqtt_user
password: mqtt123456
```

> Note: `2c914bdd-mosquitto` is the container/service name used in the tested installation. Your system may use a different internal name. If the add-on is installed from this repository and the slug has not been changed, this name is expected to work in the same way.

---

## MQTT-patched iHost add-ons

These add-ons were modified so they do not depend on the official `core_mosquitto` service through `mqtt:need`. Instead, they connect directly to the Mosquitto broker from this repository.

### Working patched add-ons

```text
hassio-ihost-ewelink-smart-home-patched/
hassio-ihost-hardware-control-patched/
hassio-ihost-zigbee2mqtt-patched/
hassio-ihost-ewelink-remote-patched/
hassio-ihost-matter-bridge-addon-patched/
```

### What is changed in the patched versions

The usual approach is:

```text
1. Remove services: ["mqtt:need"]
2. Keep armv7 support
3. Add MQTT settings to options/schema
4. Use the original armv7 Docker image from the iHost/Open Source Project
5. Add a wrapper script: run-patched.sh
6. The wrapper reads /data/options.json
7. It exports MQTT_SERVER / MQTT_USER / MQTT_PASS and compatible alias variables
8. It checks MQTT connectivity before starting the application
9. It starts the original application inside the container
```

This bypasses the situation where an add-on waits for `core_mosquitto`, while the official broker is no longer available for `armv7`.

---

## Zigbee2MQTT for iHost

Folder:

```text
hassio-ihost-zigbee2mqtt-patched/
```

Tested configuration for the built-in iHost Zigbee module:

```yaml
mqtt:
  server: mqtt://2c914bdd-mosquitto:1883
  user: mqtt_user
  password: mqtt123456

serial:
  port: /dev/ttyS4
  adapter: ember
  baudrate: 115200
  rtscts: false

frontend:
  port: 8099
```

Before running Zigbee2MQTT, it is recommended to disable ZHA if it is using the built-in Zigbee module. Otherwise both services may conflict over `/dev/ttyS4`.

---

## Pinned official add-ons for armv7

Some official Home Assistant add-ons used to support `armv7`, but were later limited to `aarch64` and `amd64`. This repository includes pinned versions of those add-ons, fixed to the last known armv7-compatible Docker images.

```text
file-editor-armv7/       -> File editor 5.8.0
samba-armv7/             -> Samba share 12.5.4
dnsmasq-armv7/           -> Dnsmasq 1.8.1
git-pull-armv7/          -> Git pull 8.0.1
rpc-shutdown-armv7/      -> RPC Shutdown 2.5
tailscale-armv7/         -> Tailscale 0.26.1
```

These add-ons are not necessarily related to MQTT. They were added because they can be useful on iHost and other armv7 systems.

### Most useful pinned add-ons for iHost

```text
Samba share armv7  -> network access to /config, /share and /backup from Windows
File editor armv7  -> browser-based YAML/file editing
Dnsmasq armv7      -> local DNS server
Git pull armv7     -> pull Home Assistant configuration from Git
RPC Shutdown armv7 -> remotely shut down Windows PCs from Home Assistant
Tailscale armv7    -> secure VPN access without port forwarding
```

---

## Installing this repository in Home Assistant

In Home Assistant:

```text
Settings -> Add-ons -> Add-on Store -> ⋮ -> Repositories
```

Add this repository URL:

```text
https://github.com/Ar4hie/ihost-mosquitto-armv7-addon-repo
```

Then run:

```text
Settings -> Add-ons -> Add-on Store -> ⋮ -> Check for updates
```

If the add-ons do not appear immediately:

```text
1. Run ha supervisor restart through SSH/Terminal
2. Refresh the browser page with Ctrl + F5
3. Open the Add-on Store again
```

Terminal command:

```bash
ha supervisor restart
```

---

## Recommended installation order on iHost

For a clean or broken setup, it is better to proceed in this order:

```text
1. Install Mosquitto broker from this repository
2. Start Mosquitto
3. Check Mosquitto logs
4. Install and start the required MQTT-patched add-ons
5. Install helper add-ons after that: Samba, File editor, Dnsmasq, etc.
```

For Zigbee2MQTT:

```text
1. Disable ZHA if it uses the built-in Zigbee module
2. Install hassio-ihost-zigbee2mqtt-patched
3. Configure the MQTT broker
4. Configure serial port /dev/ttyS4
5. Start the add-on
6. Check the frontend on port 8099
```

---

## Updating patched add-ons

If an add-on file was changed on GitHub but Home Assistant still shows an old version:

```text
1. Uninstall the installed add-on
2. Settings -> Add-ons -> Add-on Store -> ⋮ -> Check for updates
3. Run ha supervisor restart
4. Refresh the browser with Ctrl + F5
5. Install the add-on again
```

Do not keep both `config.json` and `config.yaml` in the same add-on folder. Home Assistant Supervisor may detect the manifest incorrectly.

---

## Important warnings

### 1. This is not an official Home Assistant repository

This is a community/user project for restoring `armv7` compatibility. Use it carefully and create a backup before installing or replacing add-ons.

### 2. Do not run two MQTT brokers on the same port

If another Mosquitto instance is already running on port `1883`, you may get port conflicts or MQTT service provider conflicts.

### 3. Pinned add-ons may be outdated

Pinned versions are fixed to the last known armv7-compatible images. This improves compatibility, but it also means they may not contain newer fixes from current `aarch64/amd64` releases.

### 4. iHost has limited hardware resources

Do not overload iHost with heavy workloads. For `armv7`, it is better to run lightweight services:

```text
MQTT
Zigbee2MQTT
Samba
File editor
Dnsmasq
Tailscale
simple network/service add-ons
```

Heavy workloads such as Whisper, Piper or openWakeWord are better suited for a stronger mini PC or server.

---

## Why this project exists

This project was created as a practical solution for Sonoff iHost on `armv7`: the device can still work well, but part of the official Home Assistant ecosystem is gradually dropping support for this architecture.

The goal is not to replace official Home Assistant, but to keep iHost useful and stable:

```text
- local MQTT broker;
- eWeLink / iHost add-ons without core_mosquitto dependency;
- Zigbee2MQTT on the built-in Zigbee module;
- useful pinned armv7 add-ons;
- a clear base for future forks and fixes.
```

If you have a Sonoff iHost or another Home Assistant device running on `armv7`, this repository may help restore add-ons that disappeared from the official store because of architecture support changes.

---

# Русский

Этот репозиторий создан для восстановления и продления нормальной работы **Sonoff iHost с Home Assistant на armv7**.

Основная проблема: часть официальных Home Assistant add-ons постепенно перестала публиковаться для `armv7`. Из-за этого на iHost и других armv7-устройствах некоторые дополнения больше не устанавливаются или ломаются. Особенно критично это для MQTT: официальный `core_mosquitto` больше недоступен для `armv7`, а некоторые iHost add-ons требуют MQTT через:

```yaml
services:
  - "mqtt:need"
```

Этот репозиторий решает две задачи:

1. Даёт рабочий **Mosquitto broker для armv7** с `mqtt:provide`.
2. Содержит patched/pinned версии add-ons, которые нужны Sonoff iHost или другим Home Assistant устройствам на `armv7`.

Проект в первую очередь рассчитан на **Sonoff iHost / HA OS for iHost / board ihost / armv7**, но часть дополнений может быть полезна и владельцам других armv7-устройств с Home Assistant Supervisor.

---

## Главное: Mosquitto broker для armv7

Папка:

```text
mosquitto/
```

Используется готовый официальный образ Home Assistant:

```text
homeassistant/armv7-addon-mosquitto:6.5.2
```

Ключевой момент — add-on объявляет MQTT-сервис как provider:

```yaml
services:
  - "mqtt:provide"
```

Благодаря этому Home Assistant Supervisor видит MQTT broker как доступный сервис для других add-ons.

Рекомендуемые MQTT-настройки, которые использовались при тестировании на iHost:

```yaml
server: mqtt://2c914bdd-mosquitto:1883
username: mqtt_user
password: mqtt123456
```

> Важно: `2c914bdd-mosquitto` — это имя контейнера/сервиса Mosquitto в конкретной установке. В вашей системе имя может отличаться. Если add-on установлен из этого репозитория и slug не менялся, обычно это имя работает именно так.

---

## MQTT-patched iHost add-ons

Эти дополнения были изменены так, чтобы не требовать официальный `core_mosquitto` через `mqtt:need`, а подключаться напрямую к нашему Mosquitto broker.

### Рабочие patched add-ons

```text
hassio-ihost-ewelink-smart-home-patched/
hassio-ihost-hardware-control-patched/
hassio-ihost-zigbee2mqtt-patched/
hassio-ihost-ewelink-remote-patched/
hassio-ihost-matter-bridge-addon-patched/
```

### Что изменено в patched-версиях

Обычно схема такая:

```text
1. Удалён services: ["mqtt:need"]
2. Оставлен armv7
3. Добавлены MQTT-настройки в options/schema
4. Используется оригинальный armv7 Docker image от iHost/Open Source Project
5. Добавлен wrapper run-patched.sh
6. Wrapper читает /data/options.json
7. Экспортирует MQTT_SERVER / MQTT_USER / MQTT_PASS и совместимые alias-переменные
8. Проверяет подключение к MQTT перед запуском приложения
9. Запускает оригинальное приложение внутри контейнера
```

Такая схема помогает обойти ситуацию, когда add-on ждёт `core_mosquitto`, но официальный broker уже не поддерживает `armv7`.

---

## Zigbee2MQTT для iHost

Папка:

```text
hassio-ihost-zigbee2mqtt-patched/
```

Проверенная конфигурация для встроенного Zigbee-модуля iHost:

```yaml
mqtt:
  server: mqtt://2c914bdd-mosquitto:1883
  user: mqtt_user
  password: mqtt123456

serial:
  port: /dev/ttyS4
  adapter: ember
  baudrate: 115200
  rtscts: false

frontend:
  port: 8099
```

Перед запуском Zigbee2MQTT желательно отключить ZHA, чтобы не было конфликта за `/dev/ttyS4`.

---

## Pinned official add-ons для armv7

Некоторые официальные Home Assistant add-ons раньше поддерживали `armv7`, но позже были переведены только на `aarch64` и `amd64`. Для них здесь добавлены pinned-версии — зафиксированные на последнем совместимом armv7 Docker image.

```text
file-editor-armv7/       -> File editor 5.8.0
samba-armv7/             -> Samba share 12.5.4
dnsmasq-armv7/           -> Dnsmasq 1.8.1
git-pull-armv7/          -> Git pull 8.0.1
rpc-shutdown-armv7/      -> RPC Shutdown 2.5
tailscale-armv7/         -> Tailscale 0.26.1
```

Эти add-ons не обязательно связаны с MQTT. Они добавлены потому, что могут быть полезны на iHost и других armv7-системах.

### Самые полезные из них для iHost

```text
Samba share armv7  -> доступ к /config, /share, /backup с Windows по сети
File editor armv7  -> редактирование YAML из браузера
Dnsmasq armv7      -> локальный DNS-сервер
Git pull armv7     -> подтягивание конфигурации HA из Git
RPC Shutdown armv7 -> удалённое выключение Windows-ПК из HA
Tailscale armv7    -> безопасный VPN-доступ без проброса портов
```

---

## Установка репозитория в Home Assistant

В Home Assistant:

```text
Settings -> Add-ons -> Add-on Store -> ⋮ -> Repositories
```

Добавить URL:

```text
https://github.com/Ar4hie/ihost-mosquitto-armv7-addon-repo
```

После добавления:

```text
Settings -> Add-ons -> Add-on Store -> ⋮ -> Check for updates
```

Если add-ons не появились сразу:

```text
1. Выполнить ha supervisor restart через SSH/Terminal
2. Обновить страницу браузера Ctrl + F5
3. Снова открыть Add-on Store
```

Команда для терминала Home Assistant:

```bash
ha supervisor restart
```

---

## Рекомендуемый порядок установки на iHost

Для чистой или проблемной установки лучше идти так:

```text
1. Установить Mosquitto broker из этого репозитория
2. Запустить Mosquitto
3. Проверить логи Mosquitto
4. Установить и запустить нужные MQTT-patched add-ons
5. Только после этого ставить вспомогательные add-ons: Samba, File editor, Dnsmasq и т.д.
```

Для Zigbee2MQTT:

```text
1. Отключить ZHA, если он использует встроенный Zigbee-модуль
2. Установить hassio-ihost-zigbee2mqtt-patched
3. Указать MQTT broker
4. Указать serial port /dev/ttyS4
5. Запустить add-on
6. Проверить frontend на порту 8099
```

---

## Советы по обновлению patched add-ons

Если файл add-on изменён в GitHub, а Home Assistant всё ещё показывает старую версию:

```text
1. Удалить установленный add-on
2. Settings -> Add-ons -> Add-on Store -> ⋮ -> Check for updates
3. Выполнить ha supervisor restart
4. Обновить браузер Ctrl + F5
5. Установить add-on заново
```

Не держите одновременно `config.json` и `config.yaml` в одной папке add-on. Home Assistant Supervisor может некорректно определить manifest.

---

## Важные предупреждения

### 1. Это не официальный репозиторий Home Assistant

Это пользовательский проект для восстановления совместимости `armv7`. Используйте его осознанно и делайте backup перед установкой.

### 2. Не запускайте два MQTT broker одновременно на одном порту

Если у вас каким-то образом уже работает другой Mosquitto на `1883`, возможен конфликт портов или MQTT service provider.

### 3. Некоторые pinned add-ons могут устаревать

Pinned-версии специально зафиксированы на последних известных armv7-образах. Это хорошо для совместимости, но значит, что они могут не содержать свежих исправлений из новых `aarch64/amd64` версий.

### 4. iHost имеет ограниченные ресурсы

Не стоит перегружать iHost тяжёлыми задачами. Для `armv7` лучше подходят лёгкие сервисы:

```text
MQTT
Zigbee2MQTT
Samba
File editor
Dnsmasq
Tailscale
простые сетевые add-ons
```

Тяжёлые задачи вроде Whisper/Piper/openWakeWord лучше запускать на более мощном мини-ПК или сервере.

---

## Для чего был создан проект

Этот проект появился как практическое решение проблемы Sonoff iHost на `armv7`: устройство ещё может хорошо работать, но часть официальной экосистемы Home Assistant постепенно прекращает поддержку этой архитектуры.

Цель проекта — не заменить официальный Home Assistant, а сохранить рабочую и удобную среду для iHost:

```text
- локальный MQTT broker;
- eWeLink / iHost add-ons без зависимости от core_mosquitto;
- Zigbee2MQTT на встроенном Zigbee-модуле;
- полезные armv7 pinned add-ons;
- понятная база для дальнейших форков.
```

Если у вас Sonoff iHost или другое устройство Home Assistant на `armv7`, этот репозиторий может помочь вернуть add-ons, которые исчезли из официального магазина из-за смены поддерживаемых архитектур.
