# Download Homer
FROM bash:latest AS download-homer

WORKDIR /app

RUN apk add wget gzip unzip

# renovate: datasource=github-releases depName=bastienwirtz/homer
ENV HOMER_VERSION="v24.11.5"
RUN wget https://github.com/bastienwirtz/homer/releases/download/${HOMER_VERSION}/homer.zip -O /tmp/homer.zip
RUN unzip /tmp/homer.zip -x "logo.png" -x "*.md" -d /app

RUN /usr/bin/env bash -O extglob -c 'rm -rf /app/assets/!(icons|manifest.json)'  
RUN /usr/bin/env bash -O globstar -c 'gzip -9 /app/**/*.{html,js,css,svg,ttf,json,ico}'

# Build Busybox
FROM alpine:latest AS build-busybox
ENV BUSYBOX_VERSION="1.37.0"

RUN apk add gcc musl-dev make perl
RUN wget https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2 \
  && tar xf busybox-${BUSYBOX_VERSION}.tar.bz2 \
  && mv /busybox-${BUSYBOX_VERSION} /busybox

WORKDIR /busybox
COPY .config ./

RUN make && make install
RUN adduser -D static

# Download catatonit
# renovate: datasource=github-releases depName=openSUSE/catatonit
ENV CATATONIT_VERSION="v0.2.0"
ADD https://github.com/openSUSE/catatonit/releases/download/${CATATONIT_VERSION}/catatonit.x86_64 /catatonit
RUN chmod +x /catatonit

# Compile scratch image
FROM scratch AS compile
LABEL org.opencontainers.image.source="https://github.com/trexx/docker-homer"

COPY --from=build-busybox /etc/passwd /etc/passwd
COPY --from=build-busybox /busybox/_install/bin/busybox /
COPY --from=build-busybox /catatonit /

USER static
WORKDIR /www

COPY --from=download-homer /app /www/

ENTRYPOINT ["/catatonit", "--"]
CMD ["/busybox", "httpd", "-f", "-p", "8080"]
