FROM ghcr.io/ihost-open-source-project/hassio-ihost-matter-bridge-armv7:1.2.0

COPY run-patched.sh /run-patched.sh
RUN chmod a+x /run-patched.sh

ENTRYPOINT ["/run-patched.sh"]
