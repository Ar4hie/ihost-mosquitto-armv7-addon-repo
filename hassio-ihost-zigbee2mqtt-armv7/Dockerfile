ARG BUILD_FROM=ghcr.io/home-assistant/armv7-base:3.22
FROM ${BUILD_FROM} AS base

ENV LANG=C.UTF-8
ARG BUILD_VERSION=2.12.1-1

RUN apk add --no-cache \
      curl \
      eudev \
      jq \
      nodejs \
      socat \
      tini

FROM base AS dependencies_and_build

RUN apk add --no-cache --virtual .buildtools \
      g++ \
      gcc \
      git \
      linux-headers \
      make \
      npm \
      python3 \
      udev && \
    if [ "${BUILD_VERSION}" = "edge" ]; then \
      echo "Installing Zigbee2MQTT edge"; \
      git clone --branch dev --single-branch --depth 1 \
        https://github.com/Koenkk/zigbee2mqtt.git /app; \
      mkdir -p /app/dist; \
      jq -n --arg commit "$(cd /app && git rev-parse --short HEAD)" '$commit' > /app/dist/.hash; \
    else \
      Z2M_VERSION="${BUILD_VERSION%-*}"; \
      echo "Installing Zigbee2MQTT ${Z2M_VERSION}"; \
      curl -fsSL -o /app.tar.gz \
        "https://github.com/Koenkk/zigbee2mqtt/archive/${Z2M_VERSION}.tar.gz"; \
      tar xzf /app.tar.gz; \
      rm /app.tar.gz; \
      mv "zigbee2mqtt-${Z2M_VERSION}" /app; \
      mkdir -p /app/dist; \
      jq -n --arg commit "${Z2M_VERSION}" '$commit' > /app/dist/.hash; \
    fi && \
    echo "Installed Zigbee2MQTT @ $(cat /app/dist/.hash)" && \
    cd /app && \
    npm install --global "$(jq -r '.packageManager' package.json)" && \
    pnpm install --frozen-lockfile --unsafe-perm && \
    pnpm run build && \
    rm -rf node_modules && \
    pnpm install --frozen-lockfile --no-optional --unsafe-perm --prod && \
    find ./node_modules/.pnpm/ -wholename '*/@serialport/bindings-cpp/prebuilds' -type d -prune -exec rm -rf '{}' + && \
    pnpm rebuild @serialport/bindings-cpp

FROM base AS release

WORKDIR /app

COPY --chmod=0755 rootfs /
COPY --from=dependencies_and_build /app/node_modules ./node_modules
COPY --from=dependencies_and_build /app/dist ./dist
COPY --from=dependencies_and_build /app/package.json /app/LICENSE /app/index.js ./

ENV NODE_ENV=production

HEALTHCHECK --interval=1m --timeout=3s --start-period=30s \
  CMD curl -f http://localhost:8099/ || exit 1

ENTRYPOINT ["/sbin/tini", "--", "/docker-entrypoint.sh"]
