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

BUILD_DIR="${TOP_DIR}/build/${BUILD_ID}"

if [ -n "${CI}" ]; then
  OUTPUT_DIR="${TOP_DIR}/output/"
else
  OUTPUT_DIR="${TOP_DIR}/output/${BUILD_ID}"
fi

mkdir -p "${BUILD_DIR}"

sudo podman run \
  --pull=missing \
  --rm \
  --privileged \
  -v "${TOP_DIR}:/opt/live:rbind,dev,suid" \
  -v "/dev/null:/dev/null:rbind,dev,suid" \
  -e BUILD_DIR="/opt/live/build/${BUILD_ID}" \
  -e SOURCE_DIR="/opt/live/source" \
  "ghcr.io/potassium-os/debian-live-build-env:latest" \
    /bin/bash -c "set -exu \
      && rm -rf \${BUILD_DIR} \
      && cp -Rv \${SOURCE_DIR} \${BUILD_DIR} \
      && cd \${BUILD_DIR} \
      && lb build 2>&1 | tee -a build.log \
      "

mkdir -p "${OUTPUT_DIR}"/{info,iso,boot,live}

cp -v  "${BUILD_DIR}/binary.modified_timestamps"      "${OUTPUT_DIR}/info/"
cp -v  "${BUILD_DIR}/build.log"                       "${OUTPUT_DIR}/info/"
cp -v  "${BUILD_DIR}/chroot.files"                    "${OUTPUT_DIR}/info/"
cp -v  "${BUILD_DIR}/chroot.packages.install"         "${OUTPUT_DIR}/info/"
cp -v  "${BUILD_DIR}/chroot.packages.live"            "${OUTPUT_DIR}/info/"
cp -v  "${BUILD_DIR}/live-image-amd64.contents"       "${OUTPUT_DIR}/iso/"
cp -v  "${BUILD_DIR}/live-image-amd64.files"          "${OUTPUT_DIR}/iso/"
cp -v  "${BUILD_DIR}/live-image-amd64.hybrid.iso"     "${OUTPUT_DIR}/iso/"
cp -v  "${BUILD_DIR}/live-image-amd64.packages"       "${OUTPUT_DIR}/iso/"
cp -Rv "${BUILD_DIR}/chroot/boot"/**                  "${OUTPUT_DIR}/boot"
cp -v  "${BUILD_DIR}/binary/live/filesystem.squashfs" "${OUTPUT_DIR}/live"
cp -v  "${BUILD_DIR}/binary/live/filesystem.packages" "${OUTPUT_DIR}/live"
cp -v  "${BUILD_DIR}/binary/live/initrd.img"*         "${OUTPUT_DIR}/live"
cp -v  "${BUILD_DIR}/binary/live/vmlinuz"*            "${OUTPUT_DIR}/live"
