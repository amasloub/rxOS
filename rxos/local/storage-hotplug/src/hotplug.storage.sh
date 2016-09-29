#!/bin/sh
#
# Hot-plug external storage device, redirect ONDD downloads, and trigger FSAL
# reindex.
# 
# This script is intended to run by an udev rule, and as such relies on the
# udev environment variables. In particular, the following environment
# variables are expected to be defined:
#
# - $ACTION (either 'add' or 'remove')
# - $DEVNAME (e.g., /dev/sda1)
# - $ID_FS_TYPE (e.g., 'vfat', 'ntfs', 'ext4')
# - $ID_BUS (e.g., 'usb', 'pci')
#
# Only devices with $ID_BUS value of 'usb' will be considered to avoid
# confusion with built-in storage devices like the SD card, loop devices, etc.
# 
# When manually invoking the script, the environment values can be passed on
# the command line with valid expected values.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

. /usr/lib/led_ctrl.sh

# Set PATH
PATH="/bin:/usr/bin:/sbin:/usr/sbin"
REFRESH_CMD="/usr/bin/oncontentchange"

EXTERNAL_MPOINT="/mnt/external"
NODENAME="${DEVNAME##/dev/}"
TMPMOUNT="/mnt/$NODENAME"
SUPPORTED="vfat ntfs ext2 ext3 ext4"
MOUNT_OPTS="
ntfs:windows_names,fmask=133,dmask=022,recover
vfat:utf8
"
CHECK_PKG="%CHECK_PKG%"
PLATFORM="$(cat /etc/platform)"

case "$ID_FS_TYPE" in
  ntfs)
    MOUNT_CMD="ntfs-3g"
    ;;
  *)
    MOUNT_CMD="mount -t $ID_FS_TYPE"
esac

ONDD_SOCKET="/var/run/ondd.ctrl"

# Log debug messages
log() {
  msg="$1"
  logger -t "hotplug.$NODENAME" "$msg"
  echo "$msg"
}

# Perform a fsck for given disk type. We ignore failure for filesystem types
# that do not support fsck.
do_fsck() {
  fsck."$ID_FS_TYPE" -py "$DEVNAME"
}

# Get the devices current mount point if any
#
# If the device has not been mounted, empty string is returned.
get_mpoint() {
  egrep "^$DEVNAME" /proc/mounts | awk '{print $2;}'
}

# Return true if filesystem is supported
is_supported() {
  echo "$SUPPORTED" | grep "$ID_FS_TYPE" >/dev/null 2>&1
}

# Return true if device is attached to a USB port
is_usb() {
  [ "$ID_BUS" = usb ]
}

# Mount the device to specified path using specified options
#
# Arguments:
#
#   path:   Path to the mount point
#   opts:   Mount options (passed as -o argument)
#
# If the mount point does not exist, it is created.
mount_at() {
  path="$1"
  opts="$2"
  mkdir -p "$path"
  $MOUNT_CMD -o "$opts" "$DEVNAME" "$path"
}

# Force-unmount specified device or mount point
umountf() {
  path="$1"
  umount -f "$path"
}

# Force-unmount the external storage device (if any)
umount_ext() {
  umountf "$EXTERNAL_MPOINT"
}

# Run firmware update
run_pkg() {
  log "Checking for firmware updates"
  pkg="$(find "$TMPMOUNT" -name "$PLATFORM*.pkg" -maxdepth 1 | sort | tail -n1)"
  [ -z "$pkg" ] && return 0
  [ -x "$pkg" ] || return 0
  log "Executing firmware update in $pkg"
  if "$pkg"; then
    log "Finished executing firmware update"
    exit 0
  else
    log "Failed not execute firmware update"
    return 1
  fi
}

# Log specified message and quit with non-0 return code
#
# The LED is truned off before exiting.
fail() {
  msg="$1"
  log "$msg"
  led_off
  exit 1
}

reset_led() {
  # We need a 1s pause because if we issue LED state changes too fast, then
  # they don't get applied.
  led_off
  sleep 1
  led_on
}

revert_internal() {
  mount -o bind /mnt/internal /mnt/external
}

# Handle the 'add' event
add() {
  log "Attempting to use $ID_FS_TYPE disk $DEVNAME"

  # Sanity checks
  is_usb || fail "Not an USB device, ignoring"
  is_supported || fail "$ID_FS_TYPE is not a supported filesystem."

  log "Checking disk integrity"
  led_fast_blink
  do_fsck
  led_slow_blink

  # Get mount options appropriate for this FS type
  opts="$(echo "$MOUNT_OPTS" | egrep "^$ID_FS_TYPE:" | cut -d: -f2)"
  log "Mounting with options: '${opts:=defaults}'"  # this also assigns

  # Attempt a temporary mount to determine if the disk is mountable
  log "Doing a trial mount on $TMPMOUNT"
  if ! mount_at "$TMPMOUNT" "$opts"; then
    log "Trial mount failed. Ignoring disk."
    rm -rf "$TMPMOUNT"
    exit 0
  fi

  # Check for firmware updates if needed
  [ "$CHECK_PKG" = y ] && run_pkg

  # Now we start the real-deal mounting

  umountf "$TMPMOUNT"
  umount_ext

  log "Final mount to $EXTERNAL_MPOINT"
  if ! mount_at "$EXTERNAL_MPOINT" "$opts"; then
    revert_internal
    fail "Unable to mount"
  fi

  log "Redirecting ONDD to external storage"
  log "Refreshing file index"
  $REFRESH_CMD

  reset_led
}

# Handle the 'remove' event
remove() {
  mpoint="$(get_mpoint)"
  if [ -z "$mpoint" ]; then
    log "$DEVNAME was not mounted, nothing to do"
    exit 0
  fi

  led_slow_blink

  log "Attempting to unmount from '$mpoint'"
  # We cannot umount $DEVNAME here because the device node is already gone, so
  # we must unmount the mount point instead.
  umountf "$mpoint" || fail "Could not unmount the device"
  revert_internal

  log "Refreshing file index"
  $REFRESH_CMD

  reset_led
}

log "Handling hotplug even for $DEVNAME"

$ACTION  # functions match the action name
