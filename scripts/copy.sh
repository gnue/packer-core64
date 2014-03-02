#!/bin/sh

set -e
set -x

MNT="/mnt/sda"
OPT="$MNT/opt"

sudo cp -a /home "$MNT"
sudo cp -a /opt "$MNT"
sudo cp -a /tmp/tce "$MNT"

# .filetool.lst
sudo sed -i '/^opt$/d'  "$OPT/.filetool.lst"
sudo sed -i '/^home$/d' "$OPT/.filetool.lst"
