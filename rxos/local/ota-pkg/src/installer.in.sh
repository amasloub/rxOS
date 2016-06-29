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

extract_to_bootfs() {
  filename="$1"
  $LOG "Installing $filename"
  mount -o remount,rw /boot || fail "Could not unlock boot partition"
  cp "/boot/$filename" "/boot/${filename}.backup" \
    || fail "Could not back up /boot/${filename}"
  sync
  $INSTALLER --extract "$filename" /boot \
    || fail "Could not extract $filename"
  sync
  mount -o remount,ro /boot
  $LOG "Installed /boot/$filename"
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
hasfile "zImage" && extract_to_bootfs "zImage"
hasfile "kernel.img" && extract_to_bootfs "kernel.img"
hasfile "$DTB" && extract_to_bootfs "$DTB"

if hasfile "u-boot-dtb.bin"; then
  $LOG "Installing U-Boot"
  mtdpart="$(find_mtd "U-Boot")"
  [ -z "$mtdpart" ] && fail "Could not determine the mtd partition"
  $INSTALLER --flash "u-boot-dtb.bin" "$mtdpart" \
    || fail "Could not write U-Boot"
fi

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
