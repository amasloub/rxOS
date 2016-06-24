#!/bin/bash
#
# This script programs the CHIP's NAND flash using sunxi-tools' `fel` utiltiy,
# and U-Boot itself. The U-Boot must support fastboot. The following tools must 
# be present on the system:
#
# - dd (coreutils)
# - lsusb (usbutils)
# - fel (sunxi-tools)
# - mkimage (uboot-tools)
# - fastboot (android-tools or android-tools-fastboot)
# - img2simg (android-tools, simg2img, or android-tools-fsutils)
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
# 5         -         UBI           Partition that stores ubi volumes.
# ========  ========  ============  ====================================
#
# The flashing works roughly like this:
#
# CHIP is put into FEL mode by jumping the FEL pin (3rd on U14L) to ground
# (first or last on U14L) during power-on. This allows the user to execute
# arbitrary bare-metal code on the Allwinner CPU. The `fel` tool is used to
# execute the SPL generated by the build (sunxi-spl.bin), which activates the
# DRAM. Once DRAM is active, the payload can be uploaded.
#
# One of the files that are transferred to the board's memory is a specially
# crafted U-Boot script that performs the transfer of the payload from memory
# to NAND flash. After all payloads are transferred to DRAM, the U-Boot binary
# in the memory is executed, which in turns runs the prepared U-Boot script.
#
# When the flashing of partitions 0 through 4 is done, the board is put into
# fastboot mode.
#
# The UBI partition will be flashed using fastboot client, using the UBI image
# generated by the build.
#
# This file is part of rxOS.
# rxOS is free sofware licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

set -e

SCRIPTDIR="$(dirname "$0")"

# Prefer host dirs
HOST_DIR="$(cd "$SCRIPTDIR/../out/host")"
if [ -d "$HOST_DIR" ]; then
  export PATH="$HOST_DIR/usr/bin:$HOST_DIR/usr/sbin:$PATH"
fi

# Relevant paths
BINARIES_DIR="$(pwd)"
TMPDIR=

# Execution parameters
TMPDIR_TEMPLATE="/tmp/chip-flash-XXXXXXX"
CHIP_DEVID="0525:a4a7"
FASTBOOT_ID="0x1f3a"
START="$(date '+%s.%N')"
KEEP_TMPDIR=n
PREPARE_ONLY=n

# UBI settings
PAGE_SIZE=16384
PAGE_SIZE_HEX=0x4000
OOB_SIZE=1664
PEB_SIZE=$(( 2 * 1024 * 1024 ))

# Memory locations
SPL_ADDR=0x43000000
UBOOT_ADDR=0x4a000000
#UBOOT_ENV_ADDR=0x4b000000
UBOOT_SCRIPT_ADDR=0x43100000

# Abort with an error message
abort() {
  local msg="$*"
  echo "ERROR: $msg"
  [ "$KEEP_TMPDIR" == n ] && rm -rf "$TMPDIR"
  exit 1
}

# Print usage
usage() {
  echo "Usage: $0 [-htkD] [-b PATH]"
  echo
  echo "Options:"
  echo "  -h  Show this message and exit"
  echo "  -k  Keep temporary directory"
  echo "  -b  Location of the directory containing the images"
  echo "      (defaults to current directory)"
  echo "  -P  Only prepare the payload and quit (this option "
  echo "      also selects -k)"
  echo
  echo "This program is part of rxOS."
  echo "rxOS is free software licensed under the"
  echo "GNU GPL version 3 or any later version."
  echo
  echo "(c) 2016 Outernet Inc"
  echo "Some rights reserved."
  echo
}

# Check whether a command exists
has_command() {
  local command="$1"
  which "$command" > /dev/null 2>&1
}

# Check whether a device with specific device ID exists
has_dev() {
  local devid="$1"
  lsusb | grep -q "$devid" > /dev/null 2>&1
}

# Check that the specified path exists and abort if it does not.
check_file() {
  local path="$1"
  [ -f "$path" ] || abort "File not found: '$path'
Is the build finished?"
}

# Keep executing a specified command until it succeeds or times out
#
# Arguments:
#
#   pause:    pause duration in seconds
#   message:  message shown before the command executes
#   command:  command that checks status
#
# This function performs 30 loops before timing out. In each loop, it pauses
# for the number of seconds specified by the first argument.
#
# The command must be quoted.
with_timeout() {
  local pause="$1"
  local msg="$2"
  local cmd="$3"
  echo -n "${msg}..."
  for i in {1..30}; do
    $cmd > /dev/null 2>&1 && echo "OK" && return 0
    sleep "$pause"
    echo -n "."
  done
  echo "TIMEOUT"
  return 1
}

# Perform an action using fastboot client
do_fb() {
  fastboot -i "$FASTBOOT_ID" $@
}

# Test for fastboot
has_fastboot() {
  [ -n "$(do_fb devices)" ]
}

# Wait for CHIP in FEL mode to connected
wait_for_fel() {
  with_timeout 1 "[$(timestamp)] .... Waiting for CHIP in FEL mode" "fel ver"
}

# Wait for CHIP to reconnect after being flashed
wait_for_boot() {
  with_timeout 6 "[$(timestamp)] .... Waiting for boot" "has_device $CHIP_DEVID"
}

# Wait for fastboot to recognize a CHIP in fastboot mode
wait_for_fastboot() {
  with_timeout 6 "[$(timestamp)] .... Waiting for fastboot" "has_fastboot"
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
# a stream of random bytes sources from /dev/urandom. 
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
  dd if=/dev/urandom of="$path" seek="$source_pages" bs=16k \
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
  spl-image-builder -d -r 3 -u 4096 -o "$OOB_SIZE" -o "$PAGE_SIZE" -c 1024 \
    -s 64 "$in" "$out"
}

# Print the amount of time elapsed since script was started
timestamp() {
  local current
  current="$(date '+%s.%N')"
  printf '%6.2f' "$(echo "$current - $START" | bc)"
}

# Print a section message
msg() {
  local msg="$1"
  echo "[$(timestamp)] ===> $msg"
}

# Print a subjection message
submsg() {
  local msg="$1"
  echo "[$(timestamp)] .... $msg"
}

###############################################################################
# SHOW STARTS HERE
###############################################################################

# Parse the command line options
while getopts "htkb:P" opt; do
  case $opt in
    h)
      usage
      exit 0
      ;;
    k)
      KEEP_TMPDIR=y
      ;;
    b)
      BINARIES_DIR="$OPTARG"
      ;;
    P)
      PREPARE_ONLY=y
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo
      usage
      exit 1
      ;;
  esac
done

# Source files
SPL="$BINARIES_DIR/sunxi-spl.bin"
SPL_ECC="$BINARIES_DIR/sunxi-spl-with-ecc.bin"
UBOOT="$BINARIES_DIR/u-boot-dtb.bin"
#UBOOT_ENV="$BINARIES_DIR/uboot-env.bin"
UBI_IMAGE="$BINARIES_DIR/board.ubi"

# Check prereqisites
has_command fel || abort "Missing command 'fel'
Please install https://github.com/NextThingCo/sunxi-tools"
has_command spl-image-builder || abort "Missing command 'spl-image-builder'
Please install from https://github.com/NextThingCo/CHIP-tools @210f269"
has_command mkimage || abort "Missing command 'mkimage'
Please install uboot-tools"
has_command dd || abort "Missing command 'dd'
Please install coreutils"
has_command lsusb || abort "Missing command 'lsusb'
Please install usbutils"
has_command fastboot || abort "Missing 'fastboot'
Please install android-tools[-fastboot]"
has_command img2simg || abort "Missing 'img2simg'
Please install android-toos[-fsutils] or simg2img"

# Check that sources exist
check_file "$SPL"
check_file "$SPL_ECC"
check_file "$UBOOT"
#check_file "$UBOOT_ENV"
check_file "$UBI_IMAGE"

# Create and set tempdir
TMPDIR="$(mktemp -d "$TMPDIR_TEMPLATE")"

###############################################################################
# Prepare files
###############################################################################

msg "Preparing the payloads"

submsg "Preparing the SPL binary"
SPL_SIZE=$(splsize "$SPL_ECC")

submsg "Preparing the U-Boot binary"
page_align "$UBOOT" "$TMPDIR/uboot.bin"
UBOOT_SIZE=0x400000
pad_to "$UBOOT_SIZE" "$TMPDIR/uboot.bin"

#submsg "Preparing the U-Boot env file"
#UBOOT_ENV_SIZE=0x400000

submsg "Preparing sparse UBI image"
img2simg "$UBI_IMAGE" "$TMPDIR/board.ubi" $PEB_SIZE
UBI_IMAGE="$TMPDIR/board.ubi"

###############################################################################
# Create script
###############################################################################

msg "Creating U-Boot script"
submsg "Writing script source"
cat <<EOF > "$TMPDIR/uboot.cmds"
echo "==> Setting up MTD partitions"
setenv mtdparts 'mtdparts=sunxi-nand.0:4m(spl),4m(spl-backup),4m(uboot),4m(env),-(UBI)'
saveenv
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
#echo
#echo "==> Writing U-Boot env"
#nand write ${UBOOT_ENV_ADDR} env ${UBOOT_ENV_SIZE}
echo
echo "==> Setting up boot environment"
echo
# The kerne image is usually smaller than the kernel partition. We therefore
# save the kernel image size as kernel_size environment variable.
setenv kernel_size ${LINUX_SIZE}
setenv bootargs 'consoleblank=0 earlyprintk console=ttyS0,115200 ubi.mtd=4'
setenv bootcmd 'source \${scriptaddr}; mtdparts; ubi part UBI; ubifsmount ubi0:linux; ubifsload \$fdt_addr_r /sun5i-r8-chip.dtb; ubifsload \$kernel_addr_r /zImage; bootz \$kernel_addr_r - \$fdt_addr_r'
saveenv
echo
echo "==> Disabling U-Boot script (this script)"
echo
mw \${scriptaddr} 0x0
echo
echo "==> Going into fastboot mode"
echo
fastboot 0
echo
echo "**** PRAY! ****"
echo
boot
EOF
submsg "Writing script image"
mkimage -A arm -T script -C none -n "flash CHIP" -d "$TMPDIR/uboot.cmds" \
  "$TMPDIR/uboot.scr" > /dev/null

[ "$PREPARE_ONLY" = "y" ] && exit 0

###############################################################################
# Uploading
###############################################################################

msg "Uploading payloads"

# Wait for chip in FEL mode to become available
wait_for_fel || abort "Unable to find CHIP in FEL mode"

submsg "Executing SPL"
fel spl "$SPL" || abort "Failed to execute SPL"

sleep 1

submsg "Uploading SPL"
fel write "$SPL_ADDR" "$SPL_ECC"

submsg "Uploading U-Boot"
fel write "$UBOOT_ADDR" "$TMPDIR/uboot.bin"

#submsg "Uploading U-Boot env"
#fel write "$UBOOT_ENV_ADDR" "$UBOOT_ENV"

submsg "Uploading U-Boot script"
fel write "$UBOOT_SCRIPT_ADDR" "$TMPDIR/uboot.scr"

###############################################################################
# Executing flash
###############################################################################

msg "Executing flash"
fel exe "$UBOOT_ADDR"
wait_for_fastboot || abort "Unable to find CHIP in fastboot mode"
do_fb -u flash UBI "$UBI_IMAGE" || abort "Failed to flash board image"
do_fb continue || abort "Unable to continue with the boot"

msg "Verifying"
wait_for_boot || abort "Unable to detect booted CHIP"

# Finish up
msg "Cleaning up"
[ "$KEEP_TMPDIR" == n ] && rm -rf "$TMPDIR"
