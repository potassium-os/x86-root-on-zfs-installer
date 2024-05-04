#!/bin/bash

# This script is run from /home/installer/.bashrc when login occurs on tty1 or ttyS0
# It runs as the user "installer"

function _main () {
  _log "--- start potassium-installer.sh at $(date) ---"

  # Initialize the script
  _init

  # Get configuration
  FETCH_CONFIG_RESULT="$(_fetch_config)"

  if [ "${FETCH_CONFIG_RESULT}" -eq 27 ]; then
    _log "Need to spawn interactive config setup"
    # Spawn interactive config builder
    # Spawn installer
  elif [ "${FETCH_CONFIG_RESULT}" -eq 0 ]; then
    # Spawn installer
    _log "Fetched config, proceeding with install"
  fi

  _log "--- end potassium-installer.sh at $(date) ---"
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

  _log "Testing sudo..."
  sudo id 2>&1 | _log || _log "Unable to sudo" && exit 127
}

function _fetch_config () {
  # Get param from cmdline
  CONF_URL=$(sed -e 's/^.*CONF_URL=//' -e 's/ .*$//' /proc/cmdline)

  if [ -n "${CONF_URL}" ]; then
    _log "Parsed CONF_URL from /proc/cmdline: ${CONF_URL}"
    sleep 10
    _log "Loading installer config yaml from kernel param CONF_URL: ${CONF_URL}"
    curl -s "${CONF_URL}" | tee "${HOME}/potassium-installer-config.yml"
    _log "Fetched installer configuration: \n\n"
    _log "$(cat "${HOME}/potassium-installer-config.yml")"  
    _log "\n\nEnd of installer configuration" 
    echo 0
  else
    _log "CONF_URL not specified, will spawn interactive installer for configuration"
    echo 27
  fi
}

function _log () {
  echo "[$(date +"%T")]" "$@" \
    | tee /dev/tty \
    | tee -a "${HOME}/installer.log" \
      >/dev/null
}

# Call main() to start the script
_main "$@"
