#!/bin/sh
#
# Watch the specified source folder for newly created files and
# extract them as soon as they appear.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.
USAGE='opakwatch SOURCE DESTINATION'
TAR='/bin/tar'
ONFSCHANGE='/usr/bin/oncontentchange'

if [ $# != 2 ]
then
  echo >&2 "$USAGE"
  exit 1
fi

SOURCE="$1"
DESTINATION="$2"

inotifywait -m "$SOURCE" --format '%w%f' -e close_write -e moved_to |
  while read -r filename; do
    echo "Discovered '$filename', attempting extraction..."
    $TAR xf "$filename" --directory "$DESTINATION" && rm "$filename"
    $ONFSCHANGE
  done
