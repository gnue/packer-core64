#!/bin/bash

set -e

WORKDIR=$(dirname "$0")


# read config
source "$WORKDIR/core64.conf"

# read .env
[ -f ".env" ] && source ".env"

# environment
PACKER_ISO_URL="$CORE64_PACKER_ISO_URL"
ISO_NAME="$CORE64_ISO"
BOX_FILE="$CORE64_BOX_FILE"
BOX_NAME="$CORE64_BOX_NAME"
DEVICE=${CORE64_DEVICE:-"sda1"}
PROVIDER=${CORE64_PROVIDER:-"virtualbox"}
BUILD_PATH=${BUILD_PATH:-"$WORKDIR/build"}
CACHE_PATH=${CACHE_PATH:-"$WORKDIR/cache"}

echo "$(basename $0)..."
echo
echo "  PACKER_ISO_URL    = $PACKER_ISO_URL"
echo "  ISO_NAME          = $ISO_NAME"
echo "  BOX_NAME          = $BOX_NAME"
echo "  DEVICE            = $DEVICE"
echo "  PROVIDER          = $PROVIDER"
echo
echo "  BUILD_PATH        = $BUILD_PATH"
echo "  CACHE_PATH        = $CACHE_PATH"
echo
echo "  VARGRANT_KEYS_URL = $VARGRANT_KEYS_URL"
echo


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


MOUNT_POINT="/mnt/$DEVICE"

PACKER_ISO_CHECKSUM_URL="$PACKER_ISO_URL.md5.txt"
PACKER_ISO_CHECKSUM_FILE="$CACHE_PATH/$(basename $PACKER_ISO_CHECKSUM_URL)"
ISO_FILE="$ISO_NAME"
BOX_FILE="$BUILD_PATH/$(basename $BOX_NAME)_$PROVIDER.box"


# download
[ -f "$PACKER_ISO_CHECKSUM_FILE" ] || curl -o "$PACKER_ISO_CHECKSUM_FILE" "$PACKER_ISO_CHECKSUM_URL"
[ -f "$ISO_FILE" ] || die "ERR: not found '$ISO_FILE'"

# checksum
PACKER_ISO_CHECKSUM=$(cat "$PACKER_ISO_CHECKSUM_FILE" | cut -f 1 -d ' ')
ISO_CHECKSUM=$(cat "$ISO_FILE.md5.txt" | cut -f 1 -d ' ')

[ $(md5 -q "$ISO_FILE") == "$ISO_CHECKSUM" ] || die "ERR: invalid checksum '$ISO_FILE'"

# vagrant_keys
VARGRANT_KEYS="squashfs/vagrant/usr/local/share/vagrant/vagrant_keys"
mkdir -p $(dirname "$VARGRANT_KEYS")
[ -f "$VARGRANT_KEYS" ] || curl -o "$VARGRANT_KEYS" "$VARGRANT_KEYS_URL"

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
rm -f "$BOX_FILE"

packer build \
  -var "ISO_URL=$PACKER_ISO_URL" \
  -var "ISO_CHECKSUM=$PACKER_ISO_CHECKSUM" \
  -var "ISO_FILE=$ISO_FILE" \
  -var "BOX_FILE=$BOX_FILE" \
  -var "DEVICE=$DEVICE" \
  -var "MOUNT_POINT=$MOUNT_POINT" \
  core64.json

vagrant box remove "$BOX_NAME" || true
vagrant box add "$BOX_NAME" "$BOX_FILE"

# done
echo
echo "==> $BOX_FILE"
