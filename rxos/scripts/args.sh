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

# Global variables
SCRIPTDIR=$(dirname $0)
BASEDIR=$(cd $SCRIPTDIR/../../; pwd)
BUILD=$(cd $BASEDIR; git rev-parse --short HEAD)

# Parsed arguments
TARGET_DIR=$1             # (str) Directory containing built rootfs
PLATFORM=$2               # (str) Platform name
VERSION=$3                # (str) Platform version
LINUX_VERSION=$4          # (str) Linux version used in the build
INITRAMFS_COMPRESSION=$5  # (str) Compression method used for initramfs
INITRAMFS_FILE=$6         # (str) Name of the output initramfs archive
TMPFS_SIZE=$7             # (int) Size of the overlay RAM disk (MiB)
SDSIZE=$8                 # (int) Size of the SD card partition
SDSOURCE=$9               # (str) Path to the SD card source
SDNAME=${10}              # (str) Name of the output SD card image file
VERSIONED_PKG=${11}       # (str) y if pkg should be versioned, n otherwise
