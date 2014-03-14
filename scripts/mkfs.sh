#!/bin/sh

set -e
set -x

DEVICE=${DEVICE:-"sda1"}
DEV="/dev/$DEVICE"
MNT=${MOUNT_POINT:-"/mnt/$DEVICE"}

# mkfs
mkfs.ext4 -F -L coreos-data "$DEV"

# mount
mkdir -p "$MNT"
sudo mount "$DEV" "$MNT"
