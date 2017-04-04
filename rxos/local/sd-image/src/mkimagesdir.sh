#!/bin/bash
#
# Create an images dir inside rootfs and store kernel,uboot,dtb etc in it
#
# (c) 2016 Outernet Inc
# Some rights reserved.

set -eu

. "$BR2_EXTERNAL/scripts/helpers.sh"

export PATH="${HOST_DIR}/usr/bin/:${HOST_DIR}/usr/sbin:${PATH}"

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

# Source files
LINUX="$BINARIES_DIR/zImage"
DTB="$BINARIES_DIR/sun5i-a13-dreamcatcher.dtb"
UBOOT="$BINARIES_DIR/u-boot-sunxi-with-spl.bin"
UBOOTSCRIPT="$BINARIES_DIR/boot.scr"
UBOOTSCRIPT_SRC="$BINARIES_DIR/boot.cmd"

# Check prereqisites
has_command mkimage || abort "Missing command 'mkimage'
Please install u-boot-tools"

# Check that sources exist
check_file "$DTB"
check_file "$UBOOT"
check_file "$LINUX"

# make uboot boot.scr
echo 'setenv bootargs consoleblank=0 earlyprintk console=ttyS0,115200 coherent_pool=4M BOARD=dc' > ${UBOOTSCRIPT_SRC}
echo "setenv bootcmd 'load mmc 0:1 \${kernel_addr_r} zImage && load mmc 0:1 \${fdt_addr_r} sun5i-a13-dreamcatcher.dtb && bootz \${kernel_addr_r} - \${fdt_addr_r}'" \
    >> ${UBOOTSCRIPT_SRC}
echo 'boot' >> ${UBOOTSCRIPT_SRC}
mkimage -C none -A arm -T script -d "${UBOOTSCRIPT_SRC}" "${UBOOTSCRIPT}"

# make manifest
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
rm -f /mnt/conf/etc/passwd
rm -f /mnt/conf/etc/shadow
rm -f /mnt/conf/etc/group
EOF


imagesdir="$BINARIES_DIR/images/images"

mkdir -p "$imagesdir"

if [ -z "$KEY_RELEASE" ]
then
    echo "sop_store_key" >> "$BINARIES_DIR/manifest"
    echo "Building a Key release"
else
    if [ ! -d "${BINARIES_DIR}/../../../../rxos_builds/RELEASES/${KEY_RELEASE}" ]
    then
        echo KEY_RELEASE = ${KEY_RELEASE}, but $(realpath "${BINARIES_DIR}/../../../../rxos_builds/RELEASES/${KEY_RELEASE}") does not exist.
        echo cannot continue. bailing.
        exit 1
    fi
    echo "sop_store_dlt" >> "$BINARIES_DIR/manifest"
    echo "Building a Delta release. It will NOT be stored for later use on the receiver."
fi

. "$BR2_EXTERNAL/scripts/ota_hack.sh"

cp  "$BINARIES_DIR/manifest" "$UBOOT" "$UBOOTSCRIPT" "$LINUX" "$DTB" "$imagesdir"

