#!/bin/sh

set -e
set -x

# mkfs
mkfs.ext4 -F -L coreos-data /dev/sda

# mount
mkdir -p /mnt/sda
sudo mount /dev/sda /mnt/sda
