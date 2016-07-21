#!/bin/sh
#
# Install the firmware files.
#
# This file is part of rxOS.
# rxOS is free sofware licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

VERSION="%VERSION%"
LOCAL_VERSION="$(cat /etc/version 2>/dev/null)"
IGNORE_VERSION="%IGNORE_VERSION%"
DTB="%DTB%"

INSTALLER="$1"
CONTENTS="$($INSTALLER --list)"

LOG="logger -s -t pkg.installer"

###############################################################################
# HELPER FUNCTIONS
###############################################################################

hasfile() {
  filename="$1"
  echo "$CONTENTS" | grep "$filename" >/dev/null 2>&1
}

fail() {
  msg="$*"
  $LOG "$msg"
  exit 1
}

# Find a MTD partition that is labelled w/ specified name
find_mtd() {
  label="$1"
  grep "\"$label\"" /proc/mtd 2>/dev/null | cut -d: -f1 | sed 's/mtd//'
}

# Extract a file to /boot performing a three-point swap
#
# When updating a file in the /boot directory, the update is performed using
# the following three steps:
#
# 1. rename the old copy to <filename>.backup
# 2. extract the new copy to <filename>.new
# 3. rename the <filename>.new to filename
#
# In case #2 fails, <filename>.backup is restored to <filename> and if there is
# a <filename>.new, it is removed. Failure during this step is not critical.
# 
# This update procedure assumes that the 'mv' command will always succeed or
# fail (i.e., partial mv is not possible).
extract_to_bootfs() {
  filename="$1"
  tgtpath="/boot/$filename"

  $LOG "Installing $filename to $tgtpath"
  mount -o remount,rw /boot || fail "Could not unlock boot partition"

  # Back up existing copy
  if [ -f "$tgtpath" ]; then
    mv "$tgtpath" "${tgtpath}.backup" \
      || fail "Could not back up $filename"
    sync
  fi

  # Try to extract the new copy to <filename>.new, and restore the backup if
  # that fails.
  if ! $INSTALLER --extract "$filename" "${tgtpath}.new"; then
    [ -f "${tgtpath}.backup" ] \
      && mv "${tgtpath}.backup" "$tgtpath"
    [ -f "${tgtpath}.new" ] && rm "${tgtpath}.new"
    sync
    fail "Could not extract $filename"
  fi

  # Rename the new file to correct name
  mv "${tgtpath}.new" "$tgtpath"
  sync

  mount -o remount,ro /boot
  $LOG "Installed /boot/$filename"
}

# Flash an image to a MTD partition
flash_mtd() {
  filename="$1"
  mtdname="$2"
  $LOG "Flashing $filename to $mtdname"
  mtdpart="$(find_mtd "$mtdname")"
  [ -z "$mtdpart" ] && fail "Could not find MTD partition $mtdname"
  $INSTALLER --flash "$filename" "$mtdpart" \
    || fail "Could not write to $mtdname"
}

exec_script() {
  filename="$1"
  $LOG "Executing $filename"
  $INSTALLER --extract "$filename" /tmp \
    || fail "Could not extract $filename"
  [ -x "/tmp/$filename" ] && ( "/tmp/$filename" \
    || fail "$filename failed")
  rm "/tmp/$filename"
}

###############################################################################
# VERSION COMPARISON FUNCTIONS
###############################################################################

SFXMAJ_FAC=100        # suffix factor
PAT_FAC=1000          # patch version factor
MIN_FAC=1000000       # minor release factor
MAJ_FAC=1000000000    # major release factor

# Fnd the suffix portion of the version string
suffix() {
  echo "$1" | egrep -o '(a|b|rc)[0-9]+'
}

# Find the numeric portion of the version string
mainver() {
  echo "$1" | egrep -o '[0-9]+\.[0-9]+(\.[0-9]+)?'
}

# Convert a version number to a single integer
normalize() {
  ver=$(mainver "$1")
  sfx=$(suffix "$1")
  sfxtype=$(echo "$sfx" | egrep -o "[a-z]+")
  sfxnum=$(echo "$sfx" | egrep -o "[0-9]+")
  vmaj=$(echo "$ver" | cut -d. -f1)
  vmin=$(echo "$ver" | cut -d. -f2)
  vpat=$(echo "$ver" | cut -d. -f3)

  [ -z "$vpat" ] && vpat=0
  [ -z "$sfxnum" ] && sfxnum=1

  case "$sfxtype" in
    a)
      sfxmaj=1
      ;;
    b)
      sfxmaj=2
      ;;
    rc)
      sfxmaj=3
      ;;
    *)
      sfxmaj=4
      ;;
  esac

  echo $(( MAJ_FAC * vmaj + MIN_FAC * vmin + PAT_FAC * vpat + SFXMAJ_FAC * sfxmaj + sfxnum ))
}

# Perform version comparison
vercmp() {
  pkg_version="$1"
  platform_version="$2"
  test "$(normalize "$pkg_version")" -gt "$(normalize "$platform_version")"
}

###############################################################################
# FLASHING
###############################################################################

if [ "$IGNORE_VERSION" != "y" ]; then
  vercmp "$VERSION" "$LOCAL_VERSION" || fail "Already on same or newer version"
fi

hasfile "pre-install.sh" && exec_script "pre-install.sh"

for f in "zImage" "kernel.img" "$DTB"; do
  hasfile "$f" && extract_to_bootfs "$f"
done

for f in "u-boot-tdb.bin" "u-boot.env"; do
  hasfile "$f" && flash_mtd "$f"
done

if hasfile "rootfs.ubifs"; then
  $LOG "Installing the root filesystem image"
  $INSTALLER --ubi "rootfs.ubifs" "ubi0:root" \
    || fail "Could not write the root filesystem image"
  $LOG "Installed the root filesystem image"
fi

if hasfile "rootfs.sqfs"; then
  extract_to_bootfs "rootfs.sqfs"
  chbootfsmode
  cp "/boot/rootfs.sqfs" "/boot/backup.sqfs" \
    || fail "Could not create /boot/backup.sqfs"
  sync
  chbootfsmode
fi

hasfile "post-install.sh" && exec_script "post-install.sh"

reboot
