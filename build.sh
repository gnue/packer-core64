#!/bin/bash

die() {
	echo "$1" 1>&2
	exit 1
}

set -e

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

# build
rm -f *.box

packer build \
  -var "ISO_URL=$ISO_URL" \
  -var "ISO_CHECKSUM=$ISO_CHECKSUM" \
  -var "ISO_FILE=$ISO_FILE" \
  core64.json

vagrant box remove core64 || true
vagrant box add core64 core64_virtualbox.box
