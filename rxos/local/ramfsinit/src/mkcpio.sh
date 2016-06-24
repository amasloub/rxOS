#!/bin/bash
#
# This script generates the initramfs image that can be built into the kernel.
#
# This script should be run as a post-build hook.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reerved.

set -e

. "$BR2_EXTERNAL/scripts/helpers.sh"
. "$BR2_EXTERNAL/scripts/args.sh"

INIT_DIR=${BINARIES_DIR}/initramfs
INIT_LIST=${INIT_DIR}/init.cpio
INITRAMFS=${BINARIES_DIR}/$INITRAMFS_FILE
GENCPIO="${BUILD_DIR}/linux-${LINUX_VERSION}/usr/gen_init_cpio"

if [ "$INITRAMFS_COMPRESSION" == "gzip" ]; then
  COMPRESS_CMD="gzip -n -9 -f"
elif [ "$INITRAMFS_COMPRESSION" == "lz4" ]; then
  COMPRESS_CMD="lz4 -l -9 -f"
elif [ "$INITRAMFS_COMPRESSION" == "xz" ]; then
  COMPRESS_CMD="xz --check=crc32 --lzma2=dict=1MiB"
else
  COMPRESS_CMD=cat
fi

msg "Using $INITRAMFS_COMPRESSION compression command: $COMPRESS_CMD"

# Generate the archive
msg Generating cpio file...
$GENCPIO "$INIT_LIST" | $COMPRESS_CMD > "$INITRAMFS"

# FIXME: get_init_cpio never fails, even if it encounters missing source fils,
# for example. While this is not difficult to spot, it may lead to headache if
# we're not paying attention during the build. It would e ideal if we could
# somehow tell when it fails.
