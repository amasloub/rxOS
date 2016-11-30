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
PEB_SIZE=0x400000
LEB_SIZE=0x1F8000
MAX_LEBS=4000
UBI_COMPR=lzo
UBINIZE_CFG="$BINARIES_DIR/ubinize.cfg"

# Source files
LINUX="$BINARIES_DIR/zImage"
DTB="$BINARIES_DIR/sun5i-r8-chip.dtb"
ROOTFS="$BINARIES_DIR/rootfs.tar"
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




# This script generates files that will be flashed on CHIP:
# spl
# spl with ecc
# uboot-bin
# uboot env
# uboot script
#
# all padded, converted as necessary

# the following tools much exist in the host environment
# - mkimage (u-boot-tools)
# - img2simg (android-tools, simg2img, or android-tools-fsutils)
# - spl-image-builder (chip-tools)
#
# The end result is the following flash layout:
#
# ========  ========  ============  ====================================
# mtdpart   size MB   name          description
# --------  --------  ------------  ------------------------------------
# 0         4         spl           Master SPL binary
# 1         4         spl-backup    Backup SPL binary
# 3         4         uboot         U-Boot binary
# 4         4         env           U-Boot environment
# 5         400       swap          (reserved)
# 6         -         UBI           Partition that stores ubi volumes.
# ========  ========  ============  ====================================


# UBI settings
PAGE_SIZE=16384
PAGE_SIZE_HEX=0x4000
OOB_SIZE=1664
PEB_SIZE=$(( 4 * 1024 * 1024 ))

# Memory locations
SPL_ADDR=0x43000000
UBOOT_ADDR=0x4a000000
#UBOOT_ENV_ADDR=0x4b000000
UBOOT_SCRIPT_ADDR=0x43100000
#UBI_MEM_ADDR=0x4b000000
EMPTY_UBIFS_MEM_ADDR=0x4b000000
LINUX_UBIFS_MEM_ADDR=0x4e000000


# Env settings
#
# NOTE: When modifying the script below, keep in mind the following.
#
# - Just in case: this is a U-Boot script, not a shell script
# - Use single quote for the script, but if you need to interpolate a bash
#   variable, make sure to escape all $ characters in U-Boot variables
# - The whitespace is insignificant: two or more spaces will always end up as a
#   single space in the final script, and line breaks will be stripped
# - You *must not* use line continuation with backslash, and all lines will be
#   concatenated anyway, but be sure to leave at least one space on the next
#   line when continuing the previous one (it's best to indent the next line)
# - You cannot use a line break instead of a semi-colon
#
# More useful information about U-Boot scripts:
#
#   http://compulab.co.il/utilite-computer/wiki/index.php/U-Boot_Scripts
#
MTDPARTS="sunxi-nand.0:4m(spl),4m(spl-backup),4m(uboot),4m(env),400m(swap),-(UBI)"
BOOTARGS='
consoleblank=0
earlyprintk
console=ttyS0,115200
ubi.mtd=5'
BOOTCMDS='
source ${scriptaddr};
mtdparts;
ubi part UBI;
ubifsmount ubi0:linux;
ubifsload ${fdt_addr_r} /sun5i-r8-chip.dtb ||
  ubifsload ${fdt_addr_r} /sun5i-r8-chip.dtb.backup;
for krnl in zImage zImage.backup; do
  ubifsload ${kernel_addr_r} /${krnl} &&
    bootz ${kernel_addr_r} - ${fdt_addr_r};
done;'

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

# Return the size of a padded SPL file with EEC in hex
splsize() {
  local path="$1"
  local fsize
  fsize="$(filesize "$path")"
  hex "$(( fsize / (PAGE_SIZE + OOB_SIZE) ))"
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
  ${BINARIES_DIR}/spl-image-builder -d -r 3 -u 4096 -o "$OOB_SIZE" -p "$PAGE_SIZE" -c 1024 \
    -s 64 "$in" "$out"
}

# Generate the environment and echo it
genenv() {
  cat <<EOF
timestamp=${KBUILD_BUILD_TIMESTAMP}
console=ttyS0,115200
dfu_alt_info_ram=kernel ram 0x42000000 0x1000000;fdt ram 0x43000000 0x100000;ramdisk ram 0x43300000 0x4000000
fdt_addr_r=0x43000000
fdtfile=sun5i-r8-chip.dtb
kernel_addr_r=0x42000000
mtdids=nand0=sunxi-nand.0
scriptaddr=0x43100000
stderr=serial,vga
stdin=serial,usbkbd
stdout=serial,vga
mtdids=nand0=sunxi-nand.0
mtdparts=mtdparts=$MTDPARTS
bootargs=$(echo $BOOTARGS)
bootcmd=$(echo $BOOTCMDS)
EOF
}

# Source files
SPL="$BINARIES_DIR/sunxi-spl.bin"
SPL_ECC="$BINARIES_DIR/sunxi-spl-with-ecc.bin"
UBOOT="$BINARIES_DIR/u-boot-dtb.bin"
UBI_IMAGE="$BINARIES_DIR/board.ubi"

# Check prereqisites
#has_command spl-image-builder || abort "Missing command 'spl-image-builder'
#Please install from https://github.com/NextThingCo/CHIP-tools @210f269"
has_command mkimage || abort "Missing command 'mkimage'
Please install u-boot-tools"
has_command dd || abort "Missing command 'dd'
Please install coreutils"
has_command img2simg || abort "Missing 'img2simg'
Please install android-toos[-fsutils] or simg2img"
has_command xz || abort "Missing 'xz'
Please install xz"

# Check that sources exist
check_file "$SPL"

# create spl-with-ecc reproducibly
add_ecc "$SPL" "$SPL_ECC"

check_file "$SPL_ECC"
check_file "$UBOOT"
#check_file "$UBI_IMAGE"

SPL_SIZE=$(splsize "$SPL_ECC")

page_align "$UBOOT" "$BINARIES_DIR/uboot.bin"
UBOOT_SIZE=0x400000
pad_to "$UBOOT_SIZE" "$BINARIES_DIR/uboot.bin"

# create board.ubi

msg "Tools info"
submsg "Using ubinize: $(which ubinize)"
submsg "Using mkfs.ubifs: $(which mkfs.ubifs)"

msg "Creating Linux UBIFS image"
timestamp="$(date -u +'%y%m%d%H%M')"
tmpdir="$BINARIES_DIR/rxos-flash-package-$timestamp"
mkdir -p "$tmpdir"
cp "$LINUX" "$tmpdir/zImage"
cp "$DTB" "$tmpdir/sun5i-r8-chip.dtb"
cp "$ROOTFS" "$tmpdir/rootfs_${timestamp}.tar"
mv "$ROOTFS" "$BINARIES_DIR/rootfs_${timestamp}.tar"
xz -9 "$tmpdir/rootfs_${timestamp}.tar"
cp "$tmpdir/rootfs_${timestamp}.tar.xz" "$BINARIES_DIR"

tar cf "$BINARIES_DIR/skylark-chip-${timestamp}.sop" --mtime="2016-01-01" --owner=0 --group=0 --transform 's?.*/??g' \
    "$BINARIES_DIR/uboot.bin" "$SPL_ECC" "$LINUX" "$DTB" "$ROOTFS"
xz -9 -c "$BINARIES_DIR/skylark-chip-${timestamp}.sop" > "$BINARIES_DIR/skylark-chip-${timestamp}.sop.xz"

cp -v "$BINARIES_DIR/overlays/"*.sqfs "$tmpdir" 2>/dev/null \
  || echo "WARN: Overlays not copied"  # but it's ok
mkubifs "$tmpdir" "$BINARIES_DIR/linux.ubifs"
rm -rf "$tmpdir"
mkdir "$tmpdir"
mkubifs "$tmpdir" "$BINARIES_DIR/empty.ubifs"
rm -rf "$tmpdir"

#msg "Creating board UBI image"
#mkubiimg "$UBINIZE_CFG" "$BINARIES_DIR/board.ubi"

#UBI_SIZE=`filesize "$BINARIES_DIR/board.ubi" | xargs printf "0x%08x"`
LINUX_UBIFS_SIZE=`filesize "$BINARIES_DIR/linux.ubifs" | xargs printf "0x%08x"`
EMPTY_UBIFS_SIZE=`filesize "$BINARIES_DIR/empty.ubifs" | xargs printf "0x%08x"`

###############################################################################
# Create script
###############################################################################


if [ "$NOBOOT" = y ]; then
  BOOTSCR="while true; do sleep 10; done"
else
  BOOTSCR="boot"
fi

cat <<EOF > "$BINARIES_DIR/uboot.cmds"
echo "==> Resetting environment"
env default mtdparts
env default bootargs
env default bootcmd
saveenv
echo "==> Setting up MTD partitions"
setenv mtdparts 'mtdparts=$MTDPARTS'
saveenv
mtdparts
echo
echo "==> Erasing NAND"
nand erase.chip
echo
echo "==> Writing SPL"
nand write.raw.noverify ${SPL_ADDR} spl ${SPL_SIZE}
echo
echo "==> Writing SPL backup"
nand write.raw.noverify ${SPL_ADDR} spl-backup ${SPL_SIZE}
echo
echo "==> Writing U-Boot"
nand write ${UBOOT_ADDR} uboot ${UBOOT_SIZE}
echo
echo "==> Make filesystems"
echo
ubi part UBI
ubi create "linux" 0x10000000
ubi create "root_0000000000" 0x10000000
ubi create "conf" 0x4000000
ubi create "cache" 0x10000000
ubi create "appdata" 0x26000000
ubi create "data"
echo
echo "==> Writing filesystems"
ubi writevol $LINUX_UBIFS_MEM_ADDR "linux" $LINUX_UBIFS_SIZE
ubi writevol $EMPTY_UBIFS_MEM_ADDR "root_0000000000" $EMPTY_UBIFS_SIZE
ubi writevol $EMPTY_UBIFS_MEM_ADDR "conf" $EMPTY_UBIFS_SIZE
ubi writevol $EMPTY_UBIFS_MEM_ADDR "cache" $EMPTY_UBIFS_SIZE
ubi writevol $EMPTY_UBIFS_MEM_ADDR "appdata" $EMPTY_UBIFS_SIZE
ubi writevol $EMPTY_UBIFS_MEM_ADDR "data" $EMPTY_UBIFS_SIZE
echo
echo "==> Setting up boot environment"
echo
# The kerne image is usually smaller than the kernel partition. We therefore
# save the kernel image size as kernel_size environment variable.
setenv kernel_size ${LINUX_SIZE}
setenv bootargs '$(echo $BOOTARGS)'
setenv bootcmd '$(echo $BOOTCMDS)'
saveenv
echo
echo "==> Disabling U-Boot script (this script)"
echo
mw \${scriptaddr} 0x0
echo
echo "**** PRAY! ****"
echo
$BOOTSCR
EOF

mkimage -A arm -T script -C none -n "flash CHIP" -d "$BINARIES_DIR/uboot.cmds" \
  "$BINARIES_DIR/uboot.scr" > /dev/null

rm "$BINARIES_DIR/uboot.cmds"


