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

  #
  # Setup CONF_URL

  # Valid https regex
  VALID_URL_REGEX='(https?)://[-[:alnum:]\+&@#/%?=~_|!:,.;]*[-[:alnum:]\+&@#/%=~_|]'

  # Get param from cmdline
  CONF_URL=$(sed -e 's/^.*CONF_URL=//' -e 's/ .*$//' /proc/cmdline)

  # If it's non-empty and passes regex
  if [[ (-n "${CONF_URL}") && ($CONF_URL =~ $VALID_URL_REGEX) ]]; then
    _log "Parsed CONF_URL from /proc/cmdline: ${CONF_URL}"
  else # Otherwise
    _log "Unable to find CONF_URL in /proc/cmdline, will prompt for one"

    # Prompt the user for one
    read -rp "Enter a CONF_URL: " CONF_URL

    # Ensure it passes regex
    while [[ ! ($CONF_URL =~ $VALID_URL_REGEX) ]]; do
      echo "Sorry, invalud url, try again"
      read -rp "Enter a CONF_URL: " CONF_URL
    done

    _log "CONF_URL set interactivly: ${CONF_URL}"
  fi

  # Fetch configuration from CONF_URL
  INSTALLER_CONF_YAML=$(curl -s "${CONF_URL}")

  echo "${INSTALLER_CONF_YAML}" | tee "${HOME}/potassium-installer-config.yml" | _log
  if [ -n "${INSTALLER_CONF_YAML}" ]; then
    _log "Loaded config sucessfully:"
    _log "${INSTALLER_CONF_YAML}"
    export INSTALLER_CONF_YAML
  else
    _log "INSTALLER_CONF_YAML appears to be empty, cannot continue"
    exit 128
  fi
}

# Call main() to start the script
_main "$@"
