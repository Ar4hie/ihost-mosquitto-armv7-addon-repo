# iHost / armv7 Home Assistant add-ons

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
