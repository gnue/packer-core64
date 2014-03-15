#!/bin/sh

set -e


WORKDIR=$(dirname "$0")
CMD=$(basename "$0")


# 設定ファイルを読込む
source "$WORKDIR/config/${CMD%.*}.conf"

# 環境ファイルを読込む
[ -f ".env" ] && source ".env"


# 環境変数の設定
CUSTOM_BOOT=${CUSTOM_BOOT:-"$WORKDIR/boot"}
BUILD_PATH=${BUILD_PATH:-"$WORKDIR/build"}
CACHE_PATH=${CACHE_PATH:-"$WORKDIR/cache"}

SRC_ISO="$CACHE_PATH/$(basename $SRC_URL)"
DST_ISO="$BUILD_PATH/$ISO_NAME.iso"


echo "$(basename $0)..."
echo
echo "  SRC_URL     = $SRC_URL"
echo "  ISO_NAME    = $ISO_NAME"
echo "  ISO_VOLID   = $ISO_VOLID"
echo "  CUSTOM_BOOT = $CUSTOM_BOOT"
echo
echo "  BUILD_PATH  = $BUILD_PATH"
echo "  CACHE_PATH  = $CACHE_PATH"
echo


# ISO を展開する
extract_iso() {
  local iso="$1"
  local dir="$2"
  local mpoint="/mnt/iso"

  mkdir -p "$mpoint"
  sudo mount -t iso9660  -o loop,ro "$iso" "$mpoint"
  sudo cp -a "$mpoint"/* "$dir"
  sudo umount "$mpoint"
}

# .md5.txt を出力する
md5txt() {
  local dir=$(dirname "$1")
  local fname=$(basename "$1")

  ( cd "$dir"; md5sum "$fname" > "$fname.md5.txt" )
}

# ISO を作成する
build_iso() {
  local iso="$1"
  local dir="$2"
  local name="$3"
  local cur=$(pwd)

  mkdir -p $(dirname "$iso")

  sudo mkisofs -l -J -R -V "$name" -no-emul-boot -boot-load-size 4 \
   -boot-info-table -b boot/isolinux/isolinux.bin \
   -c boot/isolinux/boot.cat -o "$DST_ISO" "$dir"

  md5txt "$DST_ISO"
}

# ISO をカスタムする
custom_iso() {
  local boot="$1"
  local dir="$2"

  sudo cp -a "$boot" "$dir"
  sudo find "$dir" -name '.DS_Store' -delete
}


# 前処理
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$BUILD_PATH"
mkdir -p "$CACHE_PATH"


# ダウンロード
[ -f "$SRC_ISO" ] || wget "$SRC_URL" -O "$SRC_ISO"


# メイン処理
extract_iso "$SRC_ISO" "$tmpdir"
custom_iso "$CUSTOM_BOOT" "$tmpdir"
build_iso "$DST_ISO" "$tmpdir" "$ISO_VOLID"

# 終了
echo
echo "==> $DST_ISO"
