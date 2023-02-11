# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine:3.17

# set version label
ARG BUILD_DATE
ARG VERSION
ARG APPRISE_TAG
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="Roxedus"

ENV APPRISE_CONFIG_DIR=/config

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --upgrade --virtual=build-dependencies \
    cargo \
    build-base \
    libffi-dev \
    openssl-dev \
    python3-dev && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache --upgrade \
    python3 \
    uwsgi \
    uwsgi-python && \
  if [ -z ${APPRISE_TAG+x} ]; then \
    APPRISE_TAG=$(curl -s https://api.github.com/repos/caronc/apprise-api/tags \
      | jq -r ". | .[0].name"); \
  fi && \
  mkdir -p /app/apprise-api && \
  curl -o \
    /tmp/apprise-api.tar.gz -L \
    "https://github.com/caronc/apprise-api/archive/${APPRISE_TAG}.tar.gz" && \
  tar xf \
    /tmp/apprise-api.tar.gz -C \
    /app/apprise-api/ --strip-components=1 && \
  echo "**** install pip packages ****" && \
  cd /app/apprise-api && \
  python3 -m ensurepip --upgrade && \
  pip3 install -U --no-cache-dir \
    pip \
    wheel && \
  pip3 install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine-3.17/ -r requirements.txt && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    $HOME/.cache \
    $HOME/.cargo \
    /tmp/*

# copy local files
COPY root/ /
EXPOSE 8000
