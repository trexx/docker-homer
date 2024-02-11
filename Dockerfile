# build stage
FROM alpine:3.19.1 as download-homer

WORKDIR /app

RUN apk add gzip unzip
RUN wget https://github.com/bastienwirtz/homer/releases/latest/download/homer.zip -O /tmp/homer.zip
RUN unzip /tmp/homer.zip -d /app
RUN gzip -r /app

# Build Busybox
FROM alpine:3.19.1 AS build-busybox
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
FROM alpine:3.19.1 AS download-tini
ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini-static /tini-static
RUN chmod +x /tini-static

# Switch to the scratch image
FROM scratch as compile
LABEL org.opencontainers.image.source https://github.com/trexx/docker-homer

COPY --from=build-busybox /etc/passwd /etc/passwd
COPY --from=build-busybox /busybox/_install/bin/busybox /
COPY --from=download-tini /tini-static /

USER static
WORKDIR /www

COPY --from=download-homer /app /www/
COPY --from=download-homer /app/assets /www/default-assets

ENTRYPOINT ["/tini-static", "--"]
CMD ["/busybox", "httpd", "-f", "-p", "8080"]