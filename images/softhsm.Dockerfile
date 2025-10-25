#syntax=docker/dockerfile:1
# see https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/reference.md
# see https://docs.docker.com/engine/reference/builder/#syntax
ARG BASE_IMAGE=alpine:3

#############################################################
# build softhsmv2 + pkcs11-proxy
#############################################################

# https://github.com/hadolint/hadolint/wiki/DL3006 Always tag the version of an image explicitly
# hadolint ignore=DL3006
FROM ${BASE_IMAGE} AS builder

SHELL ["/bin/ash", "-euo", "pipefail", "-c"]

ARG GIT_REPO
ARG GIT_BRANCH

# https://github.com/hadolint/hadolint/wiki/DL3018 Pin versions
# hadolint ignore=DL3018
RUN --mount=type=bind,source=../src,target=/mnt/shared <<EOF
  /mnt/shared/alpine-install-os-updates.sh

  echo "#################################################"
  echo "Installing required dev packages..."
  echo "#################################################"
  apk add --no-cache \
    `# required by curl:` \
    ca-certificates \
    curl \
    `# required for autogen.sh:` \
    autoconf \
    automake \
    libtool \
    `# required for configure/make:` \
    build-base \
    openssl-dev \
    `# additional packages required by softhsm:` \
    sqlite \
    sqlite-dev \
    `# additional packages required by pkcs11-proxy:` \
    bash \
    cmake \
    git \
    libseccomp-dev

EOF

# https://github.com/hadolint/hadolint/wiki/DL3003 Use WORKDIR to switch to a directory
# hadolint ignore=DL3003
RUN <<EOF
  echo "#################################################"
  echo "Building softhsm2 ..."
  echo "#################################################"
  echo "Downloading [$GIT_REPO]..."
  git clone -b "$GIT_BRANCH" --depth 1 "$GIT_REPO"
  mv SoftHSMv2* softhsm2

  cd softhsm2
  ./autogen.sh
  ./configure --with-objectstore-backend-db --disable-dependency-tracking
  make
  make install
  softhsm2-util --version

EOF


#############################################################
# build final image
#############################################################

# https://github.com/hadolint/hadolint/wiki/DL3006 Always tag the version of an image explicitly
# hadolint ignore=DL3006
FROM ${BASE_IMAGE} as final

SHELL ["/bin/ash", "-euo", "pipefail", "-c"]

# https://github.com/hadolint/hadolint/wiki/DL3018 Pin versions
# hadolint ignore=DL3018
RUN --mount=type=bind,source=../src,target=/mnt/shared <<EOF
  ls -alR /mnt/shared
EOF

RUN --mount=type=bind,source=../src,target=/mnt/shared <<EOF
  /mnt/shared/alpine-install-os-updates.sh
EOF

RUN --mount=type=bind,source=../src,target=/mnt/shared <<EOF
  echo "#################################################"
  echo "Installing required packages..."
  echo "#################################################"
  apk add --no-cache \
    bash \
    libstdc++ \
    libssl3 \
    opensc `# contains pkcs11-tool` \
    sqlite-libs \
    tini
EOF

RUN --mount=type=bind,source=../src,target=/mnt/shared <<EOF
  /mnt/shared/alpine-cleanup.sh
EOF

# copy softhsm2
COPY --from=builder /etc/softhsm* /etc/
COPY --from=builder /usr/local/bin/softhsm* /usr/local/bin/
COPY --from=builder /usr/local/lib/softhsm/libsofthsm2.so /usr/local/lib/softhsm/libsofthsm2.so
COPY --from=builder /usr/local/share/man/man1/softhsm* /usr/local/share/man/man1/
COPY --from=builder /usr/local/share/man/man5/softhsm* /usr/local/share/man/man5/

COPY ../src/bash-init.sh /opt/bash-init.sh

# Default configuration: can be overridden at the docker command line
ENV \
  INIT_SH_FILE='/opt/init-token.sh' \
  #
  TOKEN_AUTO_INIT=1 \
  TOKEN_LABEL="Test Token" \
  TOKEN_USER_PIN="1234" \
  TOKEN_USER_PIN_FILE="" \
  TOKEN_SO_PIN="5678" \
  TOKEN_SO_PIN_FILE="" \
  TOKEN_IMPORT_TEST_DATA=0 \
  #
  SOFTHSM_STORAGE=file
  #

ARG GIT_REPO
ARG GIT_BRANCH

ARG OCI_authors
ARG OCI_title
ARG OCI_description
ARG OCI_source
ARG OCI_revision
ARG OCI_version
ARG OCI_created

# https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL \
  org.opencontainers.image.title="$OCI_title" \
  org.opencontainers.image.description="$OCI_description" \
  org.opencontainers.image.source="$GIT_REPO" \
  org.opencontainers.image.revision="$OCI_revision" \
  org.opencontainers.image.version="$OCI_version" \
  org.opencontainers.image.created="$OCI_created"

LABEL maintainer="$OCI_authors"

RUN <<EOF
  echo "#################################################"
  echo "Writing build_info..."
  echo "#################################################"
  cat <<EOT >/opt/build_info
  GIT_REPO:    $GIT_REPO
  GIT_BRANCH:  $GIT_BRANCH
  GIT_COMMIT:  $OCI_revision
  IMAGE_BUILD: $OCI_created
EOT
  cat /opt/build_info

  mkdir -p /var/lib/softhsm/tokens/
  chmod -R 700 /var/lib/softhsm
  echo "alias pkcs11-tool='pkcs11-tool --module /usr/local/lib/softhsm/libsofthsm2.so'" >> /root/.bashrc

EOF

EXPOSE 2345

VOLUME "/var/lib/softhsm/"

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["/bin/bash", "/opt/run.sh"]
