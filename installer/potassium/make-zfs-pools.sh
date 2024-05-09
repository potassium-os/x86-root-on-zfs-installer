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

  _log "Selecting disks from config yaml"
  ZPOOL_DISKS_STRING=$(yq '.zpool_disks[]' <<< "${INSTALLER_CONF_YAML}" | sed 's/"//g')
  readarray -t ZPOOL_DISKS <<< "${ZPOOL_DISKS_STRING}"
  export ZPOOL_DISKS
  _log "Selected disks for installation: ${ZPOOL_DISKS[*]}"

  _log "Wiping disks and creating partitions"
  for DISK in "${ZPOOL_DISKS[@]}"; do
    # DISK="$( echo \"${DISK}\" | sed 's/"//g' )"
    _log "Wiping and creating partitions on ${DISK}"
    sudo -E /usr/sbin/wipefs -af "${DISK}"
    sudo -E /usr/sbin/sgdisk --zap-all "${DISK}"
    sudo -E /usr/sbin/sgdisk -n2:1M:+512M -t2:EF00 "${DISK}"
    sudo -E /usr/sbin/sgdisk -n3:0:+2G -t3:BF01 "${DISK}"
    sudo -E /usr/sbin/sgdisk -n4:0:0 -t4:BF00 "${DISK}"
  done

  for i in "${!ZPOOL_DISKS[@]}"; do
    DISKS_PARTS_ESP[i]="${ZPOOL_DISKS[$i]}-part2"
    DISKS_PARTS_BPOOL[i]="${ZPOOL_DISKS[$i]}-part3"
    DISKS_PARTS_RPOOL[i]="${ZPOOL_DISKS[$i]}-part4"
  done

  export DISKS_PARTS_ESP
  export DISKS_PARTS_BPOOL
  export DISKS_PARTS_RPOOL

  ZPOOL_LAYOUT=$(yq '.zpool_layout' <<< "${INSTALLER_CONF_YAML}" | sed 's/"//g')
  export ZPOOL_LAYOUT

  _log "Creating bpool on disks ${DISKS_PARTS_BPOOL[*]}"

  sudo -E zpool create \
    -o ashift=12 \
    -o autotrim=on \
    -o compatibility=grub2 \
    -o cachefile=/etc/zfs/zpool.cache \
    -O devices=off \
    -O acltype=posixacl -O xattr=sa \
    -O compression=lz4 \
    -O normalization=formD \
    -O relatime=on \
    -O canmount=off -O mountpoint=/boot -R /mnt \
    -f \
    bpool "${ZPOOL_LAYOUT}" "${DISKS_PARTS_BPOOL[@]}"

  _log "Creating rpool on disks ${DISKS_PARTS_RPOOL[*]}"

  sudo -E zpool create \
    -o ashift=12 \
    -o autotrim=on \
    -O acltype=posixacl -O xattr=sa -O dnodesize=auto \
    -O compression=lz4 \
    -O normalization=formD \
    -O relatime=on \
    -O canmount=off -O mountpoint=/ -R /mnt \
    -f \
    rpool "${ZPOOL_LAYOUT}" "${DISKS_PARTS_RPOOL[@]}"
  
  _log "Creating datasets"

  sudo -E zfs create -o canmount=off -o mountpoint=none rpool/ROOT
  sudo -E zfs create -o canmount=off -o mountpoint=none bpool/BOOT
  sudo -E zfs create -o canmount=noauto -o mountpoint=/ rpool/ROOT/debian
  sudo -E zfs mount rpool/ROOT/debian

  sudo -E zfs create -o mountpoint=/boot bpool/BOOT/debian
  sudo -E zfs create rpool/home
  sudo -E zfs create -o mountpoint=/root rpool/home/root
  sudo -E chmod 700 /mnt/root
  sudo -E zfs create -o canmount=off     rpool/var
  sudo -E zfs create -o canmount=off     rpool/var/lib
  sudo -E zfs create rpool/var/log
  sudo -E zfs create rpool/var/spool

  sudo -E zfs create -o com.sun:auto-snapshot=false rpool/var/cache
  sudo -E zfs create -o com.sun:auto-snapshot=false rpool/var/lib/nfs
  sudo -E zfs create -o com.sun:auto-snapshot=false rpool/var/tmp
  sudo -E chmod 1777 /mnt/var/tmp

  sudo -E zfs create rpool/srv

  sudo -E zfs create -o canmount=off rpool/usr
  sudo -E zfs create rpool/usr/local

 #  sudo zfs create -o com.sun:auto-snapshot=false rpool/var/lib/containers

  sudo -E mkdir /mnt/run
  sudo -E mount -t tmpfs tmpfs /mnt/run
  sudo -E mkdir /mnt/run/lock

}

# Call main() to start the script
_main "$@"
