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

  sudo chroot \
    /mnt \
    /bin/bash -c '
      umount -R /boot
      cd /root
      zfs unmount -a || true
      cd /
      zfs unmount -a || true
    '
  mount | grep -v zfs | tac | awk '/\/mnt/ {print $3}' | \
      xargs -i{} sudo -E umount -lf {}
  sudo -E zpool export -a || true

  printf '\n\n\n  Installation finished\n\n\n'
  read -rp "  Press enter to reboot, SIGINT to exit to a shell."
  sleep 5
  sudo systemctl reboot
}

# Call main() to start the script
_main "$@"
