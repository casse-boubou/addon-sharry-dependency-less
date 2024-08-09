ARG BUILD_FROM=ghcr.io/hassio-addons/base:16.2.0

# https://github.com/hassio-addons/addon-base/releases
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# https://github.com/eikek/sharry/releases
ARG SHARRY_VERSION=v1.14.0

# Add Sharry and java
RUN set -eux \
    apk update; \
    \
    apk add --no-cache --virtual .build-deps \
        unzip=6.0-r14 \
        ; \
    mkdir -p /opt; \
    curl -s -J -L -o /tmp/sharry.zip \
        "https://github.com/eikek/sharry/releases/download/${SHARRY_VERSION}/sharry-restserver-${SHARRY_VERSION#v}.zip"; \
    unzip /tmp/sharry.zip -d /opt; \
    mv /opt/sharry-restserver-${SHARRY_VERSION#v} /opt/sharry; \
    rm /tmp/sharry.zip; \
    apk del .build-deps; \
    \
    apk add --no-cache \
        mariadb-client=10.11.8-r0 \
        netcat-openbsd=1.226-r0 \
        openjdk17-jre=17.0.12_p7-r0

# Add Maria db
RUN apk add --no-cache \
        mariadb=10.11.8-r0 \
        mariadb-server-utils=10.11.8-r0 \
        pwgen=2.08-r3

ENV \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so.2" \
    S6_SERVICES_GRACETIME=18000
    
COPY --chmod=445 rootfs /
WORKDIR /

# Build arguments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Frosh" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Frosh Home Assistant Add-ons" \
    org.opencontainers.image.authors="Frosh" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://github.com/casse-boubou/hassio-addons" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
