#!/bin/bash
#
# Create UBI image containing the board partitions
#

# ========  ========  ============  ====================================
# vol_id    size MB   name          description
# --------  --------  ------------  ------------------------------------
# 1         8         linux         Linux kernel, DTB, and initramfs
# 2         128       root          Root filesystem
# 3         128       root-backup   Backup root filesystem image
# 4         32        overlays      Customization layer images
# 4         32        conf          Persistent system configuration
# 5         600       cache         Download cache
# 6         2048      appdata       Application state
# 7         -         data          Downloaded files
# ========  ========  ============  ====================================
#
# This file is part of rxOS.
# rxOS is free sofware licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

set -e

. "$BR2_EXTERNAL/scripts/helpers.sh"

export PATH="${HOST_DIR}/usr/bin/:${HOST_DIR}/usr/sbin:${PATH}"

# UBI configuration
PAGE_SIZE=0x4000
SUB_SIZE=16384
PEB_SIZE=0x200000
LEB_SIZE=0x1F8000
MAX_LEBS=200
UBI_COMPR=lzo
UBINIZE_CFG="$BINARIES_DIR/ubinize.cfg"

# Source files
LINUX="$BINARIES_DIR/zImage"
INITRAMFS="$BINARIES_DIR/initramfs.cpio.lz4"
DTB="$BINARIES_DIR/sun5i-r8-chip.dtb"

# Create ubifs filesystem image.
#
# Arguments:
#   rootdir:  path to the directory containing the files
#   output:   output image file path
#
# This function is used for the simplest possible case where all files are
# plain files and root-owned. You will need to write custom code if you need to
# change this behavior.
mkubifs() {
  local rootdir="$1"
  local output="$2"
  mkfs.ubifs --root="$rootdir" --min-io-size="$PAGE_SIZE" \
    --leb-size="$LEB_SIZE" --max-leb-cnt="$MAX_LEBS" --compr="$UBI_COMPR" \
    --squash-uids --output="$output"
}

# Create final UBI image
#
# Arguments:
#   ubicfg: path to the configuration file
#   output: path to output image file
mkubiimg() {
  local ubicfg="$1"
  local output="$2"
  ubinize --peb-size="$PEB_SIZE" --min-io-size="$PAGE_SIZE" \
    --sub-page-size="$SUB_SIZE" --output="$output" "$ubicfg"
}

msg "Tools info"
submsg "Using ubinize: $(which ubinize)"
submsg "Using mkfs.ubifs: $(which mkfs.ubifs)"

msg "Creating Linux UBIFS image"
tmpdir="$(mktemp -d "/tmp/rxos-linux-XXXXXXX")"
cp "$LINUX" "$tmpdir/zImage"
cp "$DTB" "$tmpdir/sun5i-r8-chip.dtb"
cp "$BINARIES_DIR/overlays/*.sqfs" "$tmpdir" >/dev/null 2>&1 \
  || echo "WARN: Overlays not copied"  # but it's ok
mkubifs "$tmpdir" "$BINARIES_DIR/linux.ubifs"
rm -rf "$tmpdir"

msg "Creating board UBI image"
mkubiimg "$UBINIZE_CFG" "$BINARIES_DIR/board.ubi"

