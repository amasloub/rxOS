#!/bin/bash
#
# Create SD card image.
#
# This script collets the boot files and creates an SD card image containing a
# FAT32 partition with the collected files.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

set -e

SCRIPTDIR=$(dirname $0)
. $SCRIPTDIR/helpers.sh
. $SCRIPTDIR/args.sh

TMPDIR="/tmp/rxos-sdimage-$(date +%s)"

msg "Collecting boot files"
mkdir -p "$TMPDIR"
orig_ifs=$IFS
IFS=":"
while read -r src target
do
  submsg "'$BINARIES_DIR/$src' -> '$target'"
  cp "$BINARIES_DIR/$src" "$TMPDIR/$target"
done < "$SDSOURCE"
IFS=$orig_ifs

msg "Creating $SDNAME ($SDSIZE MiB)"
dir2fat32 "$BINARIES_DIR/$SDNAME" "$SDSIZE" "$TMPDIR"

msg "Cleaning up"
rm -rf "$TMPDIR"
