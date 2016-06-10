#!/bin/sh
#
# Create partitions according to parameters set via the build configuration.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
# 
# (c) 2016 Outernet Inc
# Some rights reserved.

# Parameters
SDCARD="/dev/mmcblk0"
CONF_SIZE="+%CONF%M"      # configuration partition size
CACHE_SIZE="+%CACHE%M"    # cache partition size
DATA_SIZE="+%APPDATA%M"   # application data partition size

# fdisk commands
NEW_PARTITION=n
EXTENDED=e
LOGICAL=l
WRITE=w
EXTENDED_PARTITION_NUMBER=2
SKIP_BOOT_PARTITION=79  # first 79 sectors belong to the boot partition
DEFAULT_START=
MAX_SIZE=

# Check if we need to do anything. If there is a second partition, we have
# everything we need (probably).
[ -e "${SDCARD}p2" ] && exit 0

# Create the extra partitions
echo "$NEW_PARTITION
$EXTENDED
$EXTENDED_PARTITION_NUMBER
$SKIP_BOOT_PARTITION
$MAX_SIZE
$NEW_PARTITION
$LOGICAL
$DEFAULT_START
$CONF_SIZE
$NEW_PARTITION
$LOGICAL
$DEFAULT_START
$CACHE_SIZE
$NEW_PARTITION
$LOGICAL
$DEFAULT_START
$DATA_SIZE
$NEW_PARTITION
$LOGICAL
$DEFAULT_START
$MAX_SIZE
$WRITE
" | fdisk "$SDCARD" >/dev/null \
  || (echo "Error creating partitions"; exit 1)

# Format the partitions
for part in p5 p6 p7 p8; do
  mkfs.ext4 "$SDCARD$part" >/dev/null \
    || (echo "Error formatting partition $part"; exit 1)
done
