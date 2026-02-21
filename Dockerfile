# Download Homer
FROM bash:latest AS download-homer

RUN apk add --no-cache wget gzip unzip

# renovate: datasource=github-releases depName=bastienwirtz/homer versioning=regex:^v(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)$
ENV HOMER_VERSION="v25.11.1"
RUN wget https://github.com/bastienwirtz/homer/releases/download/${HOMER_VERSION}/homer.zip -O /tmp/homer.zip
RUN unzip /tmp/homer.zip -x "logo.png" -x "*.md" -d /tmp/app

RUN /usr/bin/env bash -O extglob -c 'rm -rf /tmp/app/assets/!(icons|manifest.json)'  
RUN /usr/bin/env bash -O globstar -c 'gzip -9 /tmp/app/**/*.{html,js,css,svg,ttf,ico}'

# Compile image
FROM ghcr.io/trexx/docker-busybox-httpd:latest AS compile
LABEL org.opencontainers.image.source="https://github.com/trexx/docker-homer"

COPY --from=download-homer /tmp/app /www/
