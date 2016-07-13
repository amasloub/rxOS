#!/bin/bash
#
# udev script to pipe the useful output to a FIFO file created by autoflasher.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

FIFO_PATH="/tmp/autoflasher.fifo"

[ -e "$FIFO_PATH" ] || exit 1

if [ -z "$BUSNUM" ] || [ -z "$DEVNUM" ]; then
  logger -st autoflasher.udev "Found CHIP with no bus/device number, ignoring"
  exit 0
fi

logger -st autoflasher.udev "Found CHIP with device ID $BUSNUM:$DEVNUM"
echo "$BUSNUM:$DEVNUM" >> "$FIFO_PATH"
