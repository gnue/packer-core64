#!/bin/sh

MNT="/mnt/sda"

sudo cp -a /home "$MNT"
sudo cp -a /opt "$MNT"
sudo cp -a /tmp/tce "$MNT"
