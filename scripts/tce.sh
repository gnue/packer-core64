#!/bin/sh

MNT=${MOUNT_POINT:-"/mnt/sda1"}
TEC="$MNT/tce"

cat >> "$TEC/onboot.lst" << EOF
vagrant.tcz
EOF
