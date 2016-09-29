#!/bin/sh

KiB=1  # Base unit is KiB
MiB=$(( 1024 * KiB ))
GiB=$(( 1024 * MiB ))

DLDIR=/mnt/internal
AVAIL="$(df -P "$DLDIR" | tail -n1 | awk '{print $4}')"  # KiB
MINFREE=$(( 200 * MiB ))  # OTA update 100 MiB + data 100 MiB
NEEDS="$(( MINFREE - AVAIL ))"  # KiB
CALLBACK="/usr/bin/oncontentchange.sh"
LOG="logger -t cleanup"

if [ "$NEEDS" -le 0 ]; then
  $LOG "Needs $MINFREE KiB, but there is already $AVAIL KiB, nothing to do"
  exit 0
fi

$LOG "Cleanup needs to free $NEEDS KiB"

filestats() {
  find "$DLDIR" -type f -exec stat -c '%Y|%s|%n' "{}" +
}

sort_by_ts() {
  sort -n -t\| -k1
}

size_freed=0
count=0

filestats | sort_by_ts | while read file; do
  if [ "$size_freed" -ge "$NEEDS" ]; then
    sync
    $LOG "Removed $count files and freed $size_freed KiB"
    break
  fi

  size="$(echo "$file" | cut -d\| -f2)"
  size="$(( size / 1024 ))"
  path="$(echo "$file" | cut -d\| -f3)"

  rm -f "$path"
  $LOG "Removed '$path' to free $size KiB"
  size_freed="$(( size_freed + size ))"
  count="$(( count + 1 ))"
done

[ -x "$CALLBACK" ] && "$CALLBACK"
