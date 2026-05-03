FROM ghcr.io/ihost-open-source-project/hassio-ihost-addon-armv7:1.1.3

COPY run-patched.sh /usr/local/bin/run-patched.sh
RUN chmod a+x /usr/local/bin/run-patched.sh

ENTRYPOINT ["/sbin/tini", "-s", "--", "/usr/local/bin/run-patched.sh"]
CMD ["node", "dist/index.js"]
