#!/bin/bash

# This script is run by fetch-ssh-key.service at boot as root

function _main () {
  _log "--- start fetch-ssh-key.sh at $(date) ---"

  # Initialize the script
  _init

  # Fetch the ssh key
  _fetch_ssh_key

  _log "--- end fetch-ssh-key.sh at $(date) ---"
}

#
# _init
# Initalizes script, sets working directory
function _init () {
  # debug mode = set -x = loud
  DEBUG="${DEBUG:-false}"
  if $DEBUG; then
    set -exu
  else
    set -eu
  fi

  # where this .sh file lives
  DIRNAME=$(dirname "$0")
  SCRIPT_DIR=$(cd "$DIRNAME" || exit 1; pwd)

  cd "${SCRIPT_DIR}" || exit 1
}

#
# _fetch_ssh_key
# Parses /proc/cmdline for SSH_KEY_URL
# And then curl's that to ~installer/.ssh/authorized_keys
function _fetch_ssh_key () {
  SSH_KEY_URL=$(cat /proc/cmdline | sed -e 's/^.*SSH_KEY_URL=//' -e 's/ .*$//')

  if [ -n "${SSH_KEY_URL}" ]; then
    sleep 10
    _log "Loading SSH key from kernel param SSH_KEY_URL: ${SSH_KEY_URL}"
    sudo -u installer mkdir -p "${HOME}/.ssh"
    sudo -u installer curl -s "${SSH_KEY_URL}" | tee "${HOME}/.ssh/authorized_keys"
  else
    _log "SSH_KEY_URL not specified, will not fetch ssh authorized_keys"
  fi
}

#
# _log
# Logs to the active tty, ~installer/installer.log, and /dev/kmesg
function _log () {
  echo "[$(date '%H:%M:%S')] " "$@" \
    | tee /dev/tty \
    | sudo -u installer tee -a "${HOME}/installer.log" \
    | tee /dev/kmesg \
      >/dev/null
}

# Call main() to start the script
_main "$@"
