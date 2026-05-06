FROM ghcr.io/ihost-open-source-project/armv7-addon-matter-server:8.1.1

COPY run-proxy-patched.sh /run-proxy-patched.sh
RUN chmod a+x /run-proxy-patched.sh

ENTRYPOINT ["/run-proxy-patched.sh"]
