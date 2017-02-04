#!/bin/bash
#
# Create UBI image containing the board partitions
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

# Source files
LINUX="$BINARIES_DIR/zImage"
DTB="$BINARIES_DIR/sun5i-a13-olinuxino.dtb"
ROOTFS="$BINARIES_DIR/rootfs.isoroot"
UBOOT="$BINARIES_DIR/u-boot-sunxi-with-spl.bin"
UBOOT_SCRIPT="$BINARIES_DIR/boot.scr"

# Check prereqisites
has_command dir2fat32 || abort "Missing command 'dir2fat32'"
has_command dd || abort "Missing command 'dd'
Please install core-utils"

msg "Creating linux fs image"
timestamp="$(date -u -d "${RXOS_TIMESTAMP//\"/}" +'%y%m%d%H%M')"
tmpdir="$BINARIES_DIR/$PRODUCT-flash-package-$timestamp"
mkdir -p "$tmpdir"
cp "$LINUX" "$DTB" "$UBOOT_SCRIPT" "$tmpdir/"

prefix="$PRODUCT-$BOARD-${timestamp}"

cp "$ROOTFS" "$BINARIES_DIR/${prefix}.unsigned.sop"


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

    sha1sum "$BINARIES_DIR/${prefix}.unsigned.sop" | head -c 40 > "$BINARIES_DIR/${prefix}.unsigned.sop.sha1"

    tweetnacl-sign "$BR2_EXTERNAL/sop.privkey" \
        "$BINARIES_DIR/${prefix}.unsigned.sop.sha1" \
        "$BINARIES_DIR/${prefix}.sha1.signed"

    head -c 64 "$BINARIES_DIR/${prefix}.sha1.signed"  > "$BINARIES_DIR/${prefix}.sig"

    cp "$BINARIES_DIR/${prefix}.unsigned.sop" "$BINARIES_DIR/${prefix}.uncompr.sop"

    cat "$BINARIES_DIR/${prefix}.sig" >>  "$BINARIES_DIR/${prefix}.uncompr.sop"

    echo "done."
else
    echo "*** No signing key at $BR2_EXTERNAL/sop.privkey. sop will not be signed. ***"
    cp "$BINARIES_DIR/${prefix}.unsigned.sop" "$BINARIES_DIR/${prefix}.uncompr.sop"
fi

echo -n "Creating cloop image..."
create_compressed_fs -q -B 64K "$BINARIES_DIR/${prefix}.uncompr.sop" "$BINARIES_DIR/${prefix}.sop" > /dev/null 2>&1
echo "done."

# sop file stored inside zip is forcibly named ksop for key releases
if [ -z ${KEY_RELEASE} ]
then
    # sop file stored inside zip is forcibly named ksop for key releases
    cp "$BINARIES_DIR/${prefix}.sop" "$BINARIES_DIR/${prefix}.ksop"
    cp "$BINARIES_DIR/${prefix}.ksop" "$tmpdir"
else
    # for delta releases, the key release ksop is also stored inside the
    # linux ubifs image so that delta updates can be made against it
    KEY_SOP=$(find ${BINARIES_DIR}/../../../../rxos_builds/RELEASES/${KEY_RELEASE}/*.ksop)
    if [ ! -f "${KEY_SOP}" ]
    then
        echo $(realpath "${KEY_SOP}" ) does not exist.
        echo cannot store ksop from key release ${KEY_RELEASE} in the boot fs. bailing.
        exit 1
    fi
    cp "$BINARIES_DIR/${prefix}.sop" "$tmpdir"
    cp "${KEY_SOP}" "$tmpdir"
fi

cp -v "$BR2_EXTERNAL/overlays/"*.sqfs "$tmpdir" 2>/dev/null \
  || echo "WARN: Overlays not copied"  # but it's ok

# put "freshburn" marker
touch "$tmpdir/freshburn"

SDSIZE=300
echo "Creating ${prefix}.img ($SDSIZE MiB) image..."
dir2fat32 "$BINARIES_DIR/${prefix}.img" "$SDSIZE" "$tmpdir"

echo  "Making image bootable..."
dd conv=notrunc if="$UBOOT" of="$BINARIES_DIR/${prefix}.img" bs=1024 seek=8

