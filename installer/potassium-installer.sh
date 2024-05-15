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
  printf '\n\n\n%s\n\n\n' "${LOGO}"
  read -rp "  Press enter to continue, SIGINT to exit."
  
  # Install steps (in order)
  # "finalize-system"
  INSTALL_STEPS=( "prerequs" "load-installer-config" "make-zfs-pools" "debootstrap-system" "chroot-system-setup" "finalize-system" )
  # run each installation step
  for STEP in "${INSTALL_STEPS[@]}"; do
    # run the step
    _log "About to run ${TOP_DIR}/potassium/${STEP}.sh"
    # shellcheck source=/dev/null
    . "${TOP_DIR}/potassium/${STEP}.sh"
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

  debian trixie root-on-zfs installer v1.2.0-rc0

END
)

# Call main() to start the script
_main "$@"
