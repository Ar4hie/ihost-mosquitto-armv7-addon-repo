FROM ghcr.io/ihost-open-source-project/hassio-ihost-ewelink-remote-armv7:0.3.1

COPY run-patched.sh /run-patched.sh
RUN chmod a+x /run-patched.sh

ENTRYPOINT ["/run-patched.sh"]
