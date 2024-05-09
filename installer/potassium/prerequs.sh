#!/bin/bash

function _main () {
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

  cd "${TOP_DIR}" || exit 1

  # Import common functions from potassium/common.sh
  # shellcheck source=common.sh
  . "${TOP_DIR}/potassium/common.sh"

  # Ensure we have sudo
  _log "Testing sudo"
  _log "Output from \"sudo -E id\": $(SUDO_ASKPASS=/bin/false sudo -EA id 2>&1)"

  if sudo -E true; then
    _log "User has sudo, proceeding"
  else
    _log "User does not have sudo, exiting"
    exit 127
  fi

  # Ensure apt/dpkg don't try to spawn a tui
  export DEBIAN_FRONTEND="noninteractive"

  _log "Installing zfs-dkms"
  
  sudo apt-get -yq update

  sudo apt-get -yq install \
    zfs-dkms \
    zfsutils-linux

  sudo systemctl disable zfs-import-cache.service
  sudo systemctl disable zfs-import.target

  sudo systemctl stop zfs-import-cache.service
  sudo systemctl stop zfs-import.target

  sudo modprobe zfs
}

# Call main() to start the script
_main "$@"
