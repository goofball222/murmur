FROM alpine

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL \
    org.opencontainers.image.vendor="The Goofball - goofball222@gmail.com" \
    org.opencontainers.image.url="https://github.com/goofball222/murmur" \
    org.opencontainers.image.title="Murmur (Mumble) Server" \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.source="https://github.com/goofball222/murmur.git" \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.licenses="Apache-2.0"

ENV \
    DEBUG=false \
    MURMUR_OPTS= \
    PGID=999 \
    PUID=999 \
    RUN_CHOWN=true

WORKDIR /opt/murmur

COPY root /

RUN set -x \
    && delgroup ping \
    && addgroup -g $PGID murmur \
    && adduser -D -G murmur -u $PUID murmur \
    && apk add -q --no-cache --virtual .build-deps \
        curl \
    && apk add -q --no-cache \
        bash shadow tzdata \
        murmur \
    && bash -c 'mkdir -p {cert,config,data,log}' \
    && chown -R murmur:murmur /opt/murmur \
    && apk del -q --purge .build-deps \
    && rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

EXPOSE 64738/tcp 64738/udp

VOLUME ["/opt/murmur/cert","/opt/murmur/config","/opt/murmur/data","/opt/murmur/log"]

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["murmur"]
