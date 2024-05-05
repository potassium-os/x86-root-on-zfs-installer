#!/usr/bin/env bash

set -e

# debug mode = set -x = loud
DEBUG="${DEBUG:-false}"
if $DEBUG; then
  set -exu
else
  set -eu
fi

# If the script wasn't sourced we need to set DIRNAME and SCRIPT_DIR
if ! (return 0 2>/dev/null)
then
  # where this .sh file lives
  DIRNAME=$(dirname "$0")
  SCRIPT_DIR=$(cd "$DIRNAME" || exit 1; pwd)
fi

DEFAULT_TOP_DIR=$(dirname "${SCRIPT_DIR}/.")
DEFAULT_TOP_DIR=$(cd "$DEFAULT_TOP_DIR" || exit 1; pwd)
TOP_DIR="${TOP_DIR:-$DEFAULT_TOP_DIR}"

# shellcheck disable=SC2018
#BUILD_ID=$(tr -dc a-z </dev/urandom | head -c 8; echo)

BUILD_ID=$(date --utc +%Y%m%d_%H%M%SZ)

BUILD_DIR="${TOP_DIR}/debian-live/build/${BUILD_ID}"

OUTPUT_DIR="${TOP_DIR}/debian-live/output/"

mkdir -p "${BUILD_DIR}"

sudo podman run \
  --pull=missing \
  --rm \
  --privileged \
  -v "${TOP_DIR}:/opt/build:rw,rbind,dev,suid,exec" \
  -v "/dev/null:/dev/null:rw,rbind,dev,suid,exec" \
  -e BUILD_DIR="/opt/build/debian-live/build/${BUILD_ID}" \
  -e SOURCE_DIR="/opt/build/debian-live/source" \
  -e APP_SRC_DIR="/opt/build/installer" \
  -e "DEBUG=true" \
  -e "VERBOSE=true" \
  "ghcr.io/potassium-os/debian-live-build-env:latest" \
    /bin/bash -c "set -exu \
      && rm -rf \${BUILD_DIR} \
      && cp -Rv \${SOURCE_DIR} \${BUILD_DIR} \
      && mkdir -p \${BUILD_DIR}/config/includes.chroot_after_packages/usr/local/bin/ \
      && cp -Rv \${APP_SRC_DIR}/* \${BUILD_DIR}/config/includes.chroot_after_packages/usr/local/bin/ || exit 1 \
      && cd \${BUILD_DIR} \
      && export MKSQUASHFS_OPTIONS=\" -no-recovery -always-use-fragments -b 1048576\" \
      && lb build 2>&1 | tee -a build.log \
      "

mkdir -p "${OUTPUT_DIR}"/{info,iso,boot,live}

cp -v  "${BUILD_DIR}/binary.modified_timestamps" "${OUTPUT_DIR}/info/"
cp -v  "${BUILD_DIR}/build.log"                  "${OUTPUT_DIR}/info/"
cp -v  "${BUILD_DIR}/chroot.files"               "${OUTPUT_DIR}/info/"
cp -v  "${BUILD_DIR}/chroot.packages.install"    "${OUTPUT_DIR}/info/"
cp -v  "${BUILD_DIR}/chroot.packages.live"       "${OUTPUT_DIR}/info/"
cp -v  "${BUILD_DIR}/live-image-amd64"*          "${OUTPUT_DIR}/iso/"
cp -Rv "${BUILD_DIR}/chroot/boot"                "${OUTPUT_DIR}/boot"
cp -Rv "${BUILD_DIR}/binary/live"                "${OUTPUT_DIR}/live"
