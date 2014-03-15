#!/bin/sh

set -e


WORKDIR=$(dirname "$0")
CMD=$(basename "$0")


# 設定ファイルを読込む
source "$WORKDIR/config/${CMD%.*}.conf"

# 環境ファイルを読込む
[ -f ".env" ] && source ".env"


# 環境変数の設定
TCE_INSTALLED=${TCE_INSTALLED:-"$WORKDIR/tce.installed"}
BUILD_PATH=${BUILD_PATH:-"$WORKDIR/build"}
CACHE_PATH=${CACHE_PATH:-"$WORKDIR/cache"}


KERNEL_SRC_PATH="$CACHE_PATH/$(basename $KERNEL_SRC_URL)"
KERNEL_CONFIG_PATH="$CACHE_PATH/$(basename $KERNEL_CONFIG_URL)"

VBOXADD_ISO_PATH="$CACHE_PATH/$(basename $VBOXADD_ISO_URL)"
DST_NAME=$(echo "$PKG_NAME" | sed -e "s/-KERNEL/-$KERNEL_VERSION/")
DST_PKG="$BUILD_PATH/$DST_NAME.tcz"


echo "$(basename $0)..."
echo
echo "  VBOXADD_ISO_URL   = $VBOXADD_ISO_URL"
echo "  VBOXADD_SRC_URL   = $VBOXADD_SRC_URL"
echo "  PKG_NAME          = $PKG_NAME"
echo
echo "  KERNEL_SRC_URL    = $KERNEL_SRC_URL"
echo "  KERNEL_CONFIG_URL = $KERNEL_CONFIG_URL"
echo
echo "  TCE_INSTALLED     = $TCE_INSTALLED"
echo "  BUILD_PATH        = $BUILD_PATH"
echo "  CACHE_PATH        = $CACHE_PATH"
echo


# カーネルソースの展開
extract_kernel_src() {
  local dir="$1"
  local curr=$(pwd)

  cd "$dir"
  rm -rf linux-*
  tar xf "$KERNEL_SRC_PATH"
  subdir=$(ls -d linux-* | head -n 1)
  cd "$subdir"
  cp "$KERNEL_CONFIG_PATH" .config

  make oldconfig >&2
  make prepare >&2
  make scripts >&2

  cd "$curr"
  echo "$dir/$subdir"
}

# VBoxGuestAdditions のソースコードを展開する
extract_vboxadd_src() {
  local iso="$1"
  local dir="$2"
  local mpoint="/mnt/iso"
  local target="$dir/vboxadd"

  # copy target
  rm -rf "$target"
  mkdir -p "$mpoint" "$target" 
  sudo mount -t iso9660  -o loop,ro "$iso" "$mpoint"
  "$mpoint/VBoxLinuxAdditions.run" --noexec --target "$target" >&2
  sudo umount "$mpoint"

  # extract
  mkdir -p "$dir"
  rm -rf "$dir/src"
  tar xf "$target/VBoxGuestAdditions-amd64.tar.bz2" src lib -C "$dir" >&2

  echo "$dir/src/"vboxguest-*
}

# カーネルモジュールのビルド
build_modules() {
  local kern_dir="$1"
  local src_dir="$2"
  local install_dir="$3"
  local curr=$(pwd)

  cd "$src_dir"

  KERN_DIR="$kern_dir" make
  mkdir -p "$install_dir"
  cp *.ko "$install_dir"

  cd "$curr"
}

# mount.vboxsf をビルド
build_mount_vboxsf() {
  local dir="$1"
  local dst="$2"
  local curr=$(pwd)

  tar xf "$VBOXADD_SRC_PATH" VirtualBox-4.3.8/src/VBox/Additions/linux/sharedfolders -C "$dir"
  cd "$dir/VirtualBox-4.3.8/src/VBox/Additions/linux/sharedfolders"

  gcc mount.vboxsf.c vbsfmount.c -o mount.vboxsf

  mkdir -p "$dst"
  cp mount.vboxsf "$dst"

  cd "$curr"
}

# ファイルを検索してコピーする
copy_find_files() {
  local src="$1"
  local name="$2"
  local dst="$3"

  mkdir -p "$dst"
  find "$src" -name "$name" -exec cp {} "$dst" \;
}

# インストールスクリプトをコピーする
copy_installed() {
  local fs="$1"
  local src=${2:-"$TCE_INSTALLED/$PKG_NAME"}

  if [ -f "$src" ]; then
    mkdir -p "$fs/usr/local/tce.installed"
    cp "$src" "$fs/usr/local/tce.installed/$DST_NAME"
  fi
}

# .md5.txt を出力する
md5txt() {
  local dir=$(dirname "$1")
  local fname=$(basename "$1")

  ( cd "$dir"; md5sum "$fname" > "$fname.md5.txt" )
}

# tcz を作成する
build_tcz() {
  local fs="$1"
  local pkg="$2"

  rm -f "$pkg"
  mksquashfs "$fs" "$pkg" -all-root
  md5txt "$pkg"
}


# 前処理
tmpdir=$(mktemp -d -p "$HOME")
trap 'rm -rf "$tmpdir"' EXIT

rootfs="$tmpdir/$PKG_NAME"

rm -rf "$rootfs"
mkdir -p "$rootfs"

mkdir -p "$BUILD_PATH"
mkdir -p "$CACHE_PATH"


# ダウンロード
[ -f "$KERNEL_SRC_PATH" ] || wget "$KERNEL_SRC_URL" -O "$KERNEL_SRC_PATH"
[ -f "$KERNEL_CONFIG_PATH" ] || wget "$KERNEL_CONFIG_URL" -O "$KERNEL_CONFIG_PATH"

[ -f "$VBOXADD_ISO_PATH" ] || wget "$VBOXADD_ISO_URL" -O "$VBOXADD_ISO_PATH"

if [ -n "$VBOXADD_SRC_URL" ]; then
  VBOXADD_SRC_PATH="$CACHE_PATH/$(basename $VBOXADD_SRC_URL)"

  [ -f "$VBOXADD_SRC_PATH" ] || wget "$VBOXADD_SRC_URL" -O "$VBOXADD_SRC_PATH"
fi


set -x

# メイン処理
kern_dir=$(extract_kernel_src "$tmpdir")
src_dir=$(extract_vboxadd_src "$VBOXADD_ISO_PATH" "$tmpdir")
build_modules "$kern_dir" "$src_dir" "$rootfs/usr/local/lib/modules/$KERNEL_VERSION/kernel/vboxadd"

if [ -f "$VBOXADD_SRC_PATH" ]; then
  build_mount_vboxsf "$tmpdir" "$rootfs/usr/local/sbin"
  copy_installed "$rootfs"
else
  copy_find_files "$tmpdir/lib" "mount.*" "$rootfs/usr/local/sbin"
  copy_installed "$rootfs" "$TCE_INSTALLED/$PKG_NAME-lib64"
fi

build_tcz "$rootfs" "$DST_PKG"

# 終了
echo
echo "==> $DST_PKG"
