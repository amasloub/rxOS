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


fn_exists()
{
    type $1 | grep -q 'shell function'
}


tgz_handler() {
    filename="$1"
    destination="$2"
    $TAR xf "$filename" --directory "$destination" && rm "$filename"
}

# inotify wait exits if there is an error in the called scrips,
# run it in a loop
while true
do
    # if watched directory doesn't exist, inotifywatch doesn't start
    [ -d "$SOURCE" ] || mkdir "$SOURCE"

    inotifywait -m -r "$SOURCE" --format '%w%f' -e close_write -e moved_to |
    while read -r filename
    do
        if [ -f $filename ]
        then
            # get extension
            pak_type="${filename##*.}"
            handler="${pak_type}_handler"
            if fn_exists ${handler}
            then
                echo "Discovered '$filename', calling ${handler}..."
                ${handler} "$filename" "$DESTINATION"
                $ONFSCHANGE
            else
                echo "Ignoring '$filename', as there is no ${handler}"
            fi
        fi
   done
 sleep 2
done
