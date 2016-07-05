#!/bin/bash
#
# Read from a FIFO pipe and flash a chip with specified identifier.
#
# This file is part of rxOS.
# rxOS is free software released under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

FIFO_PATH="/tmp/autoflasher.fifo"
FLASHKIT_PATH="$(dirname "$0")"
LOGDIR="$FLASHKIT_PATH/logs"
FLASHSCRIPT="$FLASHKIT_PATH/chip-flash.sh"

PATH="$PATH:$FLASHKIT_PATH/bin"
export PATH

echo "Creating FIFO pipe at '$FIFO_PATH'"
[ -e "$FIFO_PATH" ] && rm "$FIFO_PATH"
mkfifo "$FIFO_PATH"

echo "Creating log directory. Log files are stored in '$LOGDIR'"
mkdir -p "$LOGDIR"

echo "Listening for device IDs..."
while true; do
  while read -r devid; do
    echo "Got device ID: $devid"
    logpath="$LOGDIR/$(date '+%Y%m%d-%H%M%S')-$devid.log"
    "$FLASHSCRIPT" -D "$devid" >"$logpath" 2>&1 &
  done < "$FIFO_PATH"
done
