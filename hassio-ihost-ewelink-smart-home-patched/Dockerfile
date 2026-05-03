ARG BUILD_FROM=ghcr.io/ihost-open-source-project/hassio-ihost-ewelink-smart-home-armv7:1.1.0
FROM ${BUILD_FROM}

COPY run-patched.sh /run-patched.sh
RUN chmod a+x /run-patched.sh

ENTRYPOINT ["/run-patched.sh"]
