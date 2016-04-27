#!/bin/bash

# This script is used to parse all post-build and post-image hook arguments and
# make them more accessible to the hook scripts.
#
# It should be sourced from the hook scripts.
#
#
# Copyright 2016 Outernet Inc
# Some rights reserved.
#
# Released under GPLv3. See COPYING file in the source tree.

TARGET_DIR=$1             # (str) Directory containing built rootfs
LINUX_VERSION=$2          # (str) Linux version used in the build
INITRAMFS_COMPRESSION=$3  # (str) Compression method used for initramfs
