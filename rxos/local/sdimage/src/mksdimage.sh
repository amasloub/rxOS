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

SCRIPTDIR="${BR2_EXTERNAL}/scripts"
. $SCRIPTDIR/helpers.sh
. $SCRIPTDIR/args.sh

TMPDIR="$(mktemp -d /tmp/rxos-sdimage-XXXX)"

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

msg "Adding overlays"
find "$BINARIES_DIR/overlays" -name "overlay-*.sqfs" 2>/dev/null \
  | while read -r overlay; do
  submsg "Adding $(basename $overlay)"
  install "$overlay" "$TMPDIR" 
done

msg "Adding additional files"
find "$BINARIES_DIR/sdcard-extras" -type f 2>/dev/null \
  | while read -r extra; do
  submsg "Adding $(basename $extra)"
  install "$extra" "$TMPDIR"
done

msg "Creating $SDNAME ($SDSIZE MiB)"
dir2fat32 "$BINARIES_DIR/$SDNAME" "$SDSIZE" "$TMPDIR"

msg "Cleaning up"
rm -rf "$TMPDIR"
