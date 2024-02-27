# Download Homer
FROM bash:latest as download-homer

WORKDIR /app

RUN apk add wget gzip unzip

# renovate: datasource=github-releases depName=bastienwirtz/homer versioning=loose
ENV HOMER_VERSION "140992663"
RUN wget https://github.com/bastienwirtz/homer/releases/${HOMER_VERSION}/download/homer.zip -O /tmp/homer.zip
RUN unzip /tmp/homer.zip -x "logo.png" -x "*.md" -d /app

RUN /usr/bin/env bash -O extglob -c 'rm -rf /app/assets/!(icons|manifest.json)'  
RUN /usr/bin/env bash -O globstar -c 'gzip -9 /app/**/*.{html,js,css,svg,ttf,json,ico}'

# Build Busybox
FROM alpine:latest AS build-busybox
ARG BUSYBOX_VERSION=1.36.1

RUN apk add gcc musl-dev make perl
RUN wget https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2 \
  && tar xf busybox-${BUSYBOX_VERSION}.tar.bz2 \
  && mv /busybox-${BUSYBOX_VERSION} /busybox

WORKDIR /busybox
COPY .config ./

RUN make && make install
RUN adduser -D static

# Download Tini
# renovate: datasource=github-releases depName=krallin/tini versioning=loose
ENV TINI_VERSION "v0.19.0"
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static /tini-static
RUN chmod +x /tini-static

# Compile scratch image
FROM scratch as compile
LABEL org.opencontainers.image.source https://github.com/trexx/docker-homer

COPY --from=build-busybox /etc/passwd /etc/passwd
COPY --from=build-busybox /busybox/_install/bin/busybox /
COPY --from=build-busybox /tini-static /

USER static
WORKDIR /www

COPY --from=download-homer /app /www/

ENTRYPOINT ["/tini-static", "--"]
CMD ["/busybox", "httpd", "-f", "-p", "8080"]