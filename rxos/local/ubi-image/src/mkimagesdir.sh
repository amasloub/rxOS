#!/bin/bash
#
# Create UBI image containing the board partitions
#
# (c) 2016 Outernet Inc
# Some rights reserved.

set -eu

. "$BR2_EXTERNAL/scripts/helpers.sh"

export PATH="${HOST_DIR}/usr/bin/:${HOST_DIR}/usr/sbin:${PATH}"

# NAND settings for spl ecc
PAGE_SIZE=16384
PAGE_SIZE_HEX=0x4000

abort() {
  local msg="$*"
  echo "ERROR: $msg"
  [ "$KEEP_TMPDIR" == n ] && rm -rf "$TMPDIR"
  exit 1
}

# Check whether a command exists
has_command() {
  local command="$1"
  which "$command" > /dev/null 2>&1
}

# Check that the specified path exists and abort if it does not.
check_file() {
  local path="$1"
  [ -f "$path" ] || abort "File not found: '$path'
Is the build finished?"
}

# Print a number in hex format
hex() {
  local num="$1"
  printf "0x%X" "$num"
}

# Return the size of a file in bytes
filesize() {
  local path="$1"
  stat -c%s "$path"
}

# Return the size of a file in hex
hexsize() {
  local path="$1"
  hex "$(filesize "$path")"
}

# Return the size of a file in pages
pagesize() {
  local path="$1"
  local fsize
  fsize="$(filesize "$path")"
  hex "$((fsize / PAGE_SIZE))"
}

# Align a file to page boundary
#
# Arguments:
#
#   in:   input file path
#   out:  output file path
page_align() {
  local in="$1"
  local out="$2"
  dd if="$in" of="$out" bs=$PAGE_SIZE conv=sync status=none
}

# Pad a file to specified size
#
# Arguments:
#
#   size: target size (in hex notiation)
#   path: path of the file to pad
#
# This function modifies the original file by appending the padding. Padding is
# a stream of zero bytes sources from /dev/zero.
#
# It is the caller's responsibility to ensure that the target size is larger
# than the current size.
pad_to() {
  local padded_size="$1"
  local path="$2"
  local source_size_hex
  local dpages
  source_size_hex="$(hexsize "$path")"
  source_pages="$(( source_size_hex / PAGE_SIZE_HEX ))"
  dpages="$(( (padded_size - source_size_hex) / PAGE_SIZE_HEX ))"
  dd if=/dev/zero of="$path" seek="$source_pages" bs=16k \
    count="$dpages" status=none
}

# Create padded SPL with EEC (error correction code)
#
# Arguments:
#
#   in:   path to the source SPL binary
#   out:  output path
#
# This is a thin wrapper around `spl-image-builder` too provided by NTC. The
# arguments are as follows:
#
#   -d    disable scrambler
#   -r    repeat count
#   -u    usable page size
#   -o    OOB size
#   -p    page size
#   -c    ECC step size
#   -s    ECC strength
add_ecc() {
  local in="$1"
  local out="$2"
  ${BINARIES_DIR}/spl-image-builder -d -r 3 -u 4096 -o 1664 -p "$PAGE_SIZE" -c 1024 \
    -s 64 "$in" "${out}.1664"
  ${BINARIES_DIR}/spl-image-builder -d -r 3 -u 4096 -o 1280 -p "$PAGE_SIZE" -c 1024 \
    -s 64 "$in" "${out}.1280"
}

# Source files
LINUX="$BINARIES_DIR/zImage"
DTB="$BINARIES_DIR/sun5i-r8-chip.dtb"
SPL="$BINARIES_DIR/sunxi-spl.bin"
SPL_ECC="$BINARIES_DIR/sunxi-spl-with-ecc.bin"
UBOOT="$BINARIES_DIR/u-boot-dtb.bin"

# Check prereqisites
#has_command spl-image-builder || abort "Missing command 'spl-image-builder'
#Please install from https://github.com/NextThingCo/CHIP-tools @210f269"
has_command mkimage || abort "Missing command 'mkimage'
Please install u-boot-tools"
has_command dd || abort "Missing command 'dd'
Please install coreutils"
has_command img2simg || abort "Missing 'img2simg'
Please install android-toos[-fsutils] or simg2img"

# Check that sources exist
check_file "$SPL"

# create spl-with-ecc reproducibly
add_ecc "$SPL" "$SPL_ECC"

check_file "${SPL_ECC}.1664"
check_file "${SPL_ECC}.1280"
check_file "$UBOOT"

page_align "$UBOOT" "$BINARIES_DIR/uboot.bin"
UBOOT_SIZE=0x400000
pad_to "$UBOOT_SIZE" "$BINARIES_DIR/uboot.bin"

cat <<EOF > "$BINARIES_DIR/manifest"
# (c) 2016 Outernet Inc
# Skylark OTA update package
# Manifest file

# install_method filename installparam1 installparam2 ...
# supported install methods are: part_cp,  mtd_nandwrite

part_cp sun5i-r8-chip.dtb /boot
part_cp zImage /boot
mtd_nandwrite uboot.bin uboot
part_cp sunxi-spl-with-ecc.bin.1664 /boot
part_cp sunxi-spl-with-ecc.bin.1280 /boot
rm /mnt/conf/passwd
rm /mnt/conf/shadow
rm /mnt/conf/group
EOF

if [ "$KEY_RELEASE" = "yes" ]
then
    echo "sop_store_key" >> "$BINARIES_DIR/manifest"
    echo "Building a Key release: to be stored on receiver."
else
    echo "sop_store" >> "$BINARIES_DIR/manifest"
    echo "Building a point release. It will NOT be stored for later use on the receiver."
fi

imagesdir="$BINARIES_DIR/images/images"

mkdir -p "$imagesdir"

cp  "$BINARIES_DIR/manifest" "$BINARIES_DIR/uboot.bin" "${SPL_ECC}.1664" "${SPL_ECC}.1280" "$LINUX" "$DTB" "$imagesdir"
