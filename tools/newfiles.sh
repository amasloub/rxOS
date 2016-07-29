#!/bin/bash
#
# Move files found in out/target, that are not part of the previously built
# image, to specified directory. Each file that matches this criteria will also
# be printed to STDOUT.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

OUTPUT="$1"
SCRIPTDIR="$(dirname "$0")"
BUILD_DIR="$SCRIPTDIR/../out"
FILE_LIST="$BUILD_DIR/images/filelist.txt"
TARGET_DIR="$BUILD_DIR/target"
IGNORE="THIS_IS_NOT_YOUR_ROOT_FILESYSTEM"
KILL_LIST="
$OUTPUT/usr/share/doc
$OUTPUT/usr/share/man
$OUTPUT/usr/share/info
$OUTPUT/usr/share/locale
$OUTPUT/usr/share/pixmaps
$OUTPUT/usr/share/applications
"
DIFF="diff --suppress-common-lines"

usage() {
  cat <<EOF
Usage: $0 OUTPUT

Parameters:

    OUTPUT    output directory


This file is part of rxOS.
rxOS is free software licensed under the
GNU GPL version 3 or any later version.

(c) 2016 Outernet Inc
Some rights reserved.

EOF
}

install_new() {
  local file="$1"
  install -D "$TARGET_DIR/$file" "$OUTPUT/$file"
  rm "$TARGET_DIR/$file"
}

build_filelist() {
  local flist
  flist="$(mktemp /tmp/filelist-XXXX)"
  (cd "$TARGET_DIR" && find -type f 2>/dev/null | sed 's|\./||') > "$flist"
  echo "$flist"
}

get_diff() {
  local flist="$1"
  $DIFF "$FILE_LIST" "$flist" | egrep "^> " | sed 's|> ||' | grep -v "$IGNORE"
}

if [ -z "$OUTPUT" ]; then
  usage
  exit 0
fi

flist="$(build_filelist)"
fdiff="$(get_diff "$flist")"
echo "$fdiff"
echo "$fdiff" | while read -r file; do
  install_new "$file"
done
rm "$flist"

[ -d "$OUTPUT" ] && rm -rf $KILL_LIST
