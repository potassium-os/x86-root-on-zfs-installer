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

DEFAULT_TOP_DIR=$(dirname "${SCRIPT_DIR}/../.")
DEFAULT_TOP_DIR=$(cd "$DEFAULT_TOP_DIR" || exit 1; pwd)
TOP_DIR="${TOP_DIR:-$DEFAULT_TOP_DIR}"

sudo podman run \
  --rm \
  -it \
  --privileged \
  -v "${TOP_DIR}:/opt/live:rbind,dev,suid" \
  -v "/dev/null:/dev/null:rbind,dev,suid" \
  "localhost/local/debian-live-build-env:dev" \
    /bin/bash -c "${@}"
