#!/bin/sh

# Get param from cmdline
SSH_KEY_URL=$(/usr/bin/cat /proc/cmdline | /usr/bin/sed -e 's/^.*SSH_KEY_URL=//' -e 's/ .*$//')

if [ -n "${SSH_KEY_URL}" ]; then
  sleep 10
  /usr/bin/echo "Loading SSH key from kernel param SSH_KEY_URL: ${SSH_KEY_URL}" | /usr/bin/tee /dev/kmesg
  /usr/bin/sudo -u installer curl -s "${SSH_KEY_URL}" | /usr/bin/tee /home/installer/.ssh/authorized_keys
else
  /usr/bin/echo "SSH_KEY_URL not specified, will not fetch ssh authorized_keys" | /usr/bin/tee /dev/kmesg
fi
