#!/bin/sh
#
# Change the mount for the boot partition to read-write or read-only
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

BOOTPART=1
BOOTDEV="/dev/mmcblk0p$BOOTPART"

# Return 0 if boot device is mounted read-only
is_ro() {
  egrep "^$BOOTDEV" /proc/mounts | awk '{print $4}' | egrep ^ro \
    > /dev/null 2>&1
}

# Change the mount mode (read-only or read-write)
#
# Arguments:
#   mode: 'ro' or 'rw'
chmode() {
  mode="$1"
  mount -o remount,"$mode" /boot > /dev/null
}

if [ "$USER" != "root" ]; then
  echo "ERROR: you must be root to change /boot mode"
  exit 1
fi

if is_ro; then
  echo "Changing /boot to read-write mode."
  chmode rw
else
  echo "Changing /boot to read-only mode."
  chmode ro
fi
