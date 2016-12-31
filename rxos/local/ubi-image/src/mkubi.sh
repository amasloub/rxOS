#!/bin/bash
#
# Create UBI image containing the board partitions
#
# (c) 2016 Outernet Inc
# Some rights reserved.

set -eu

. "$BR2_EXTERNAL/scripts/helpers.sh"

export PATH="${HOST_DIR}/usr/bin/:${HOST_DIR}/usr/sbin:${PATH}"

# UBI configuration
PAGE_SIZE=16384
PAGE_SIZE_HEX=0x4000
OOB_SIZE=1664
SUB_SIZE=16384
PEB_SIZE=0x400000
LEB_SIZE=0x1F8000
MAX_LEBS=4000
UBI_COMPR=lzo
UBINIZE_CFG="$BINARIES_DIR/ubinize.cfg"

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
  mkfs.ubifs --root="$rootdir" --min-io-size="$PAGE_SIZE_HEX" \
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
  ubinize --peb-size="$PEB_SIZE" --min-io-size="$PAGE_SIZE_HEX" \
    --sub-page-size="$SUB_SIZE" --output="$output" "$ubicfg"
}

# Memory locations
SPL_ADDR1=0x43000000
SPL_ADDR2=0x43800000
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
MTDPARTS="sunxi-nand.0:4m(spl),4m(spl-backup),4m(uboot),4m(env),64m(swap),-(UBI)"
BOOTARGS='
consoleblank=0
earlyprintk
console=ttyS0,115200
ubi.mtd=5'
BOOTCMDS='
source ${scriptaddr};
mtdparts;
nand info;
ubi part UBI;
ubifsmount ubi0:linux;
test $nand_oobsize -eq 680 &&
    ubifsload 0x43000000 sunxi-spl-with-ecc.bin.1664 &&
    nand erase.part spl &&
    nand write.raw.noverify 0x43000000 spl 0xC4 &&
    echo "Wrote sunxi-spl-with-ecc.bin.1664 to spl" &&
    nand erase.part spl-backup &&
    nand write.raw.noverify 0x43000000 spl-backup 0xC4 &&
    echo "Wrote sunxi-spl-with-ecc.bin.1664 to spl-backup";
test $nand_oobsize -eq 500 &&
    ubifsload 0x43000000 sunxi-spl-with-ecc.bin.1280 &&
    nand erase.part spl &&
    nand write.raw.noverify 0x43000000 spl 0xC4 &&
    echo "Wrote sunxi-spl-with-ecc.bin.1280 to spl" &&
    nand erase.part spl-backup &&
    nand write.raw.noverify 0x43000000 spl-backup 0xC4 &&
    echo "Wrote sunxi-spl-with-ecc.bin.1280 to spl-backup";
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

# Return the size of a padded SPL file with EEC in hex
splsize() {
  local path="$1"
  local fsize
  fsize="$(filesize "$path")"
  hex "$(( fsize / (PAGE_SIZE + OOB_SIZE) ))"
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
# Source files
LINUX="$BINARIES_DIR/zImage"
DTB="$BINARIES_DIR/sun5i-r8-chip.dtb"
ROOTFS="$BINARIES_DIR/rootfs.isoroot"

SPL_ECC="$BINARIES_DIR/sunxi-spl-with-ecc.bin"
SPL_SIZE=$(splsize "$SPL_ECC")
UBOOT="$BINARIES_DIR/u-boot-dtb.bin"
UBOOT_SIZE=0x400000
UBI_IMAGE="$BINARIES_DIR/board.ubi"

# Check prereqisites
#has_command spl-image-builder || abort "Missing command 'spl-image-builder'
#Please install from https://github.com/NextThingCo/CHIP-tools @210f269"
has_command mkimage || abort "Missing command 'mkimage'
Please install u-boot-tools"


msg "Tools info"
submsg "Using ubinize: $(which ubinize)"
submsg "Using mkfs.ubifs: $(which mkfs.ubifs)"

msg "Creating Linux UBIFS image"
timestamp="$(date -u -d "${RXOS_TIMESTAMP//\"/}" +'%y%m%d%H%M')"
tmpdir="$BINARIES_DIR/skylark-flash-package-$timestamp"
mkdir -p "$tmpdir"
cp "$LINUX" "$tmpdir/zImage"
cp "$DTB" "$tmpdir/sun5i-r8-chip.dtb"

cp "$ROOTFS" "$BINARIES_DIR/skylark-chip-${timestamp}.unsigned.sop"


if [ -f "$BR2_EXTERNAL/sop.privkey" ]
then
    # how signing works:
    # take the 40 char sha1sum of file (just the sum, not the full output)
    # sign that - this gives a 104 byte signed file
    # the first 64 bytes is the sign, the last 40 bytes is your original sha1sum
    # we discard this sum, just keep the sign
    # we concat these together , first our sop file, then the sign. this is our signed file
    # why sign is suffixed not prefixed: it simplifies things at the client end.
    echo -n "Signing..."

    sha1sum "$BINARIES_DIR/skylark-chip-${timestamp}.unsigned.sop" | head -c 40 > "$BINARIES_DIR/skylark-chip-${timestamp}.unsigned.sop.sha1"

    tweetnacl-sign "$BR2_EXTERNAL/sop.privkey" \
        "$BINARIES_DIR/skylark-chip-${timestamp}.unsigned.sop.sha1" \
        "$BINARIES_DIR/skylark-chip-${timestamp}.sha1.signed"

    head -c 64 "$BINARIES_DIR/skylark-chip-${timestamp}.sha1.signed"  > "$BINARIES_DIR/skylark-chip-${timestamp}.sig"

    cp "$BINARIES_DIR/skylark-chip-${timestamp}.unsigned.sop" "$BINARIES_DIR/skylark-chip-${timestamp}.uncompr.sop"

    cat "$BINARIES_DIR/skylark-chip-${timestamp}.sig" >>  "$BINARIES_DIR/skylark-chip-${timestamp}.uncompr.sop"

    echo "done."

    echo -n "Creating cloop image..."
    create_compressed_fs -q -B 64K "$BINARIES_DIR/skylark-chip-${timestamp}.uncompr.sop" "$BINARIES_DIR/skylark-chip-${timestamp}.sop" > /dev/null 2>&1
    echo "done."

    # sop file stored inside zip is forcibly named ksop
    cp "$BINARIES_DIR/skylark-chip-${timestamp}.sop" "$BINARIES_DIR/skylark-chip-${timestamp}.ksop"
    cp "$BINARIES_DIR/skylark-chip-${timestamp}.ksop" "$tmpdir"
else
    echo " *** No signing key at $BR2_EXTERNAL/sop.privkey. sop cannot be signed. signing is not optional. ***"
    exit 1
fi

echo -n "Creating ubifs images..."
cp -v "$BR2_EXTERNAL/overlays/"*.sqfs "$tmpdir" 2>/dev/null \
  || echo "WARN: Overlays not copied"  # but it's ok
mkubifs "$tmpdir" "$BINARIES_DIR/linux.ubifs"
rm -rf "$tmpdir"
mkdir "$tmpdir"
mkubifs "$tmpdir" "$BINARIES_DIR/empty.ubifs"
rm -rf "$tmpdir"

LINUX_UBIFS_SIZE=`filesize "$BINARIES_DIR/linux.ubifs" | xargs printf "0x%08x"`
EMPTY_UBIFS_SIZE=`filesize "$BINARIES_DIR/empty.ubifs" | xargs printf "0x%08x"`

echo "done."

###############################################################################
# Create script
###############################################################################


echo -n "Creating uboot script..."

NOBOOT="n"

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
nand info
echo
echo "==> Erasing NAND"
nand erase.chip
echo
echo "==> Writing SPL"
test \$nand_oobsize -eq 680 && nand write.raw.noverify ${SPL_ADDR1} spl ${SPL_SIZE} && echo "wrote OOB=1664 spl"
test \$nand_oobsize -eq 500 && nand write.raw.noverify ${SPL_ADDR2} spl ${SPL_SIZE} && echo "wrote OOB=1280 spl"
echo
echo "==> Writing SPL backup"
test \$nand_oobsize -eq 680 && nand write.raw.noverify ${SPL_ADDR1} spl-backup ${SPL_SIZE} && echo "wrote OOB=1664 spl"
test \$nand_oobsize -eq 500 && nand write.raw.noverify ${SPL_ADDR2} spl-backup ${SPL_SIZE} && echo "wrote OOB=1280 spl"
echo
echo "==> Writing U-Boot"
nand write ${UBOOT_ADDR} uboot ${UBOOT_SIZE}
echo
echo "==> Make filesystems"
echo
ubi part UBI
ubi create "linux" 0xC800000
ubi create "conf" 0x4000000
ubi create "data"
echo
echo "==> Writing filesystems"
ubi writevol $LINUX_UBIFS_MEM_ADDR "linux" $LINUX_UBIFS_SIZE
ubi writevol $EMPTY_UBIFS_MEM_ADDR "conf" $EMPTY_UBIFS_SIZE
ubi writevol $EMPTY_UBIFS_MEM_ADDR "data" $EMPTY_UBIFS_SIZE
echo
echo "==> Setting up boot environment"
echo
# The kerne image is usually smaller than the kernel partition. We therefore
# save the kernel image size as kernel_size environment variable.
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

echo "done."
