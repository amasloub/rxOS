#!/bin/sh
#
# Install overlay image.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
# 
# (c) 2016 Outernet Inc
# Some rights reserved.

OVERLAY_FILE="%OVERLAY_FILE%"
OVERLAY_NAME="%OVERLAY_NAME%"
OVERLAY_VERSION="%OVERLAY_VERSION%"
TARGET_VERSION="%TARGET_VERSION%"
LOCAL_VERSION="$(cat /etc/version)"

LOG="logger -s -t pkg.installer"

INSTALLER="$1"

fail() {
  msg="$*"
  $LOG "$msg"
  mount -o remount,ro /boot
  exit 1
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

# Do not install on wrong platform version if target version is specified
if [ "$TARGET_VERSION" != "any" ] && [ "$LOCAL_VERSION" != "$TARGET_VERSION" ]; then
  fail "This overlay is for $TARGET_VERSION but $LOCAL_VERSION was found"
fi

# Find existing overlay in bootfs
#
# While it's technically possible to have more than one overlay of the same
# name, we will operate on the assumption that this is not going to be the
# case.
#
original=$(find /boot -name "overlay-${OVERLAY_NAME}-*.sqfs" | tail -n1)

[ -z "$original" ] && fail "No overlays to update"

# Get the original overlay version, perform version check
if [ -n "$OVERLAY_VERSION" ] && [ -n "$original" ]; then
  original_file=$(basename "$original")
  original_version=$(echo "$original_file" | sed 's/.sqfs//' | cut -d- -f3)
  if ! vercmp "$OVERLAY_VERSION" "$original_version"; then
    fail "Same or newer version already installed."
  fi
fi

$LOG "Installing $OVERLAY_NAME"
mount -o remount,rw /boot || fail "Could not unlock boot partition"
$LOG "Removing all backups"
rm "/boot/overlay-${OVERLAY_NAME}-*.sqfs.backup"
if [ -n "$original" ]; then
  cp "$original" "${original}.backup" \
    || fail "Could not back up ${original}"
  sync
fi
if ! $INSTALLER --extract "$OVERLAY_FILE" /boot; then
  [ -n "$original" ] && mv "${original}.backup" "${original}" && sync
  fail "Could not extract $OVERLAY_FILE"
fi
sync
mount -o remount,ro /boot
$LOG "Installed $OVERLAY_NAME"

reboot
