#!/bin/bash

# This scripts adds a trailer to the kernel image so that it can boot
# successfully on Pi3.
#
# According to the Pi kernel documentation, for Pi2 and Pi3 kernels, a script 
# called mkknlimg, which is found in the kernel's scripts directory, must be 
# run to convert the kernel into a format that can boot successfully on these 
# boards (support for DTB, etc).
#
#
# Copyright 2016 Outernet Inc
# Some rights reserved.
#
# Released under GPLv3. See COPYING file in the source tree.

set -e

SCRIPTDIR=$(dirname $0)
. ${SCRIPTDIR}/helpers.sh
. ${SCRIPTDIR}/args.sh

KRNLDIR=$BUILD_DIR/linux-$LINUX_VERSION
MKKNLIMG=${KRNLDIR}/scripts/mkknlimg
IMAGE=$BINARIES_DIR/zImage
OUTPUT=$BINARIES_DIR/kernel.img

msg Patching $IMAGE
$MKKNLIMG "$IMAGE" "$OUTPUT"
msg Generated $OUTPUT
