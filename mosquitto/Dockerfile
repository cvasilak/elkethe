FROM alpine:3.3

ENV BUILD_PACKAGES mosquitto

RUN apk update && \
    apk upgrade && \
    apk add $BUILD_PACKAGES && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /mqtt/config /mqtt/data /mqtt/log && \
    chown -R mosquitto:mosquitto /mqtt

COPY config /mqtt/config

VOLUME ["/mqtt/config", "/mqtt/data", "/mqtt/log"]

EXPOSE 1883 9001
CMD /usr/sbin/mosquitto -c /mqtt/config/mosquitto.conf

