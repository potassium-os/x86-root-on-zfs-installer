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

  sudo -E debootstrap bookworm /mnt
}

# Call main() to start the script
_main "$@"
