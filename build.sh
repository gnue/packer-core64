#!/bin/bash

die() {
  echo "$1" 1>&2
  exit 1
}

# create .md5.txt
md5txt() {
  local path="$1"
  local fname=$(basename "$path")
  local curr=$(pwd)

  cd $(dirname "$path")
  md5sum "$fname" > "$fname.md5.txt"
  cd "$curr"
}

# for OS X
if [[ -z "$(which md5sum)" && -n "$(which md5)" ]]; then
  md5sum() {
    md5 -r "$@"
  }
fi


set -e


DEVICE="sda"
MOUNT_POINT="/mnt/$DEVICE"

# http://www.tinycorelinux.net/ports.html

LATEST_RELEASE="5.2"
ISO_BASENAME="CorePure64"

ISO_URL="http://www.tinycorelinux.net/5.x/x86_64/release/$ISO_BASENAME-$LATEST_RELEASE.iso"
ISO_FILE="tmp/CorePure64-$LATEST_RELEASE.iso"

# download
if [ ! -f "$ISO_FILE" ]; then
  curl -o "$ISO_FILE.md5.txt" "$ISO_URL.md5.txt"
  curl -o "$ISO_FILE" "$ISO_URL"
fi

# checksum
ISO_CHECKSUM=$(cat "$ISO_FILE.md5.txt" | cut -f 1 -d ' ')

[ $(md5 -q "$ISO_FILE") == "$ISO_CHECKSUM" ] || die "ERR: invalid checksum"

# vagrant_keys
VARGRANT_KEYS="files/local/vagrant_keys"
[ -f "$VARGRANT_KEYS" ] || curl -o "$VARGRANT_KEYS" https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub

# squashfs
SQUASHFS_DIR="files/squashfs"

rm -rf "$SQUASHFS_DIR"
mkdir "$SQUASHFS_DIR"

for fs in squashfs/*
do
  if [ -d "$fs" ]; then
    pkgname=$(basename "$fs")
    mksquashfs "$fs" "$SQUASHFS_DIR/$pkgname.tcz" -all-root
    md5txt "$SQUASHFS_DIR/$pkgname.tcz"
  elif [[ "$fs" =~ \.tcz$ ]]; then
    cp "$fs" "$SQUASHFS_DIR"
    [ -f "$fs.md5.txt" ] && cp "$fs.md5.txt" "$SQUASHFS_DIR"
  fi
done

# build
rm -f *.box

packer build \
  -var "ISO_URL=$ISO_URL" \
  -var "ISO_CHECKSUM=$ISO_CHECKSUM" \
  -var "ISO_FILE=$ISO_FILE" \
  -var "DEVICE=$DEVICE" \
  -var "MOUNT_POINT=$MOUNT_POINT" \
  core64.json

vagrant box remove core64 || true
vagrant box add core64 core64_virtualbox.box
