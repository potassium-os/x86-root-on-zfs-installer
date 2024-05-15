#!/bin/bash

# This script is run by fetch-ssh-key.service at boot as root

function _main () {
  echo "--- start fetch-ssh-key.sh at $(date) ---"

  # Fetch the ssh key
  _fetch_ssh_key

  echo "--- end fetch-ssh-key.sh at $(date) ---"
}

#
# _fetch_ssh_key
# Parses /proc/cmdline for SSH_KEY_URL
# And then curl's that to ~installer/.ssh/authorized_keys
function _fetch_ssh_key () {
  SSH_KEY_URL=$(cat /proc/cmdline | sed -e 's/^.*SSH_KEY_URL=//' -e 's/ .*$//')

  HOME="/home/installer"

  if [ -n "${SSH_KEY_URL}" ]; then
    sleep 10
    echo "Loading SSH key from kernel param SSH_KEY_URL: ${SSH_KEY_URL}"
    sudo -u installer mkdir -p "${HOME}/.ssh"
    sudo -u installer curl -s "${SSH_KEY_URL}" | sudo -u installer tee "${HOME}/.ssh/authorized_keys"
  else
    echo "SSH_KEY_URL not specified, will not fetch ssh authorized_keys"
  fi
}

# Call main() to start the script
_main "$@"
