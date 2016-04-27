#!/bin/bash

# This script generates the initramfs image that can be built into the kernel.
# This script should be run as a post-build hook.

set -e

SCRIPTDIR=$(dirname $0)
. $SCRIPTDIR/helpers.sh
. $SCRIPTDIR/args.sh

LIBC=${TARGET_DIR}/lib/libc.so.6
LD=${TARGET_DIR}/lib/ld-linux*.so.3
LIBC_VER=$(echo $(readlink $LIBC) | grep -Poe '\d+\.\d+')
LD_VER=$(echo $(readlink $LD) | grep -Poe '\d+\.\d+')
LD_SFX=$(echo $LD | sed 's|.*/lib/ld-linux||' | sed 's|\.so\.3||')

SRCDIR=${BR2_EXTERNAL}/initramfs
TMPDIR=/tmp/initcpio-$(date +%s)

INIT_LIST=${SRCDIR}/init.cpio.in
INIT_SCRIPT=${SRCDIR}/init.in
INIT_LIST_OUT=${TMPDIR}/init.cpio
INIT_SCRIPT_OUT=${TMPDIR}/init
INITRAMFS=${BINARIES_DIR}/rootfs.cpio

KERNEL_DIR=${BUILD_DIR}/linux-${LINUX_VERSION}
GENCPIO=${KERNEL_DIR}/usr/gen_init_cpio

mkdir -p $TMPDIR

# Patch the input scirpts
msg Generating cpio configuration...
cat "$INIT_LIST" \
    | sed "s|%PREFIX%|${TARGET_DIR}|g" \
    | sed "s|%INIT%|${INIT_SCRIPT_OUT}|g" \
    | sed "s|%LIBC_VER%|${LIBC_VER}|g" \
    | sed "s|%LD_VER%|${LD_VER}|g" \
    | sed "s|%LD_SFX%|${LD_SFX}|g" \
    > "$INIT_LIST_OUT"
cat "$INIT_SCRIPT" \
    | sed "s|%TMPFS_SIZE%|${TMPFS_SIZE}|" \
    > "$INIT_SCRIPT_OUT"

# Generate the archive
msg Generating cpio file...
$GENCPIO "$TMPDIR/init.cpio" | lz4 -9 > "$INITRAMFS"

msg Cleaning up...
rm -rf $TMPDIR
