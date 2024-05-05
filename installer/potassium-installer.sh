#!/bin/bash

# This script is run from /home/installer/.bashrc when login occurs on tty1 or ttyS0
# It runs as the user "installer"

function _main () {
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

  DEFAULT_TOP_DIR=$(dirname "${SCRIPT_DIR}/.")
  DEFAULT_TOP_DIR=$(cd "$DEFAULT_TOP_DIR" || exit 1; pwd)
  TOP_DIR="${TOP_DIR:-$DEFAULT_TOP_DIR}"

  cd "${TOP_DIR}" || exit 1

  # Import common functions from potassium/common.sh
  # shellcheck source=potassium/common.sh
  . "${TOP_DIR}/potassium/common.sh"

  clear
  printf '\n\n%s\n\n' "${LOGO}"
  read -rp "  Press enter to continue"
  
  # Install steps (in order)
  INSTALL_STEPS=("prerequs" "load-installer-config" "build-zfs-kmod" "make-zfs-pools" "debootstrap-system" "chroot" "finalize")
  INSTALL_SKIP_STEPS="${INSTALL_SKIP_STEPS:-()}"
  SKIP_STEPS=()
  IFS=' ' read -r -a SKIP_STEPS <<< "${INSTALL_SKIP_STEPS}"

  # run each installation step
  for STEP in "${INSTALL_STEPS[@]}"; do
    # if current step is NOT in INSTALL_SKIP_STEPS
    # shellcheck disable=SC2076
    if ! [[ " ${SKIP_STEPS[*]} " =~ " ${STEP} " ]]; then
      # run the step
      _log "About to run ${TOP_DIR}/potassium/${STEP}.sh"
      # shellcheck source=/dev/null
      . "${TOP_DIR}/potassium/${STEP}.sh"
    else
      _log "Skipping install step: ${STEP}"
    fi
  done
}

LOGO=$(cat <<END

  ╔════════════════════════════╗  
  ║                            ║  
  ║                            ║  
  ║                            ║  
  ║          ██╗  ██╗          ║
  ║          ██║ ██╔╝          ║
  ║          █████╔╝           ║
  ║          ██╔═██╗           ║
  ║          ██║  ██╗          ║
  ║          ╚═╝  ╚═╝          ║  
  ║                            ║  
  ║                            ║  
  ║                            ║  
  ╚════════════════════════════╝  
  Potassium
  root-on-zfs installer v0.0.1

END
)

# Call main() to start the script
_main "$@"
