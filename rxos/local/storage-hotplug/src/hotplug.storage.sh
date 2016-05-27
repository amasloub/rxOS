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

PRIMARY_MPOINT="/mnt/downloads"
EXTERNAL_MPOINT="/mnt/external"
NODENAME="${DEVNAME##/dev/}"
TMPMOUNT="/mnt/$NODENAME"
SUPPORTED="vfat ntfs ext2 ext3 ext4"
MOUNT_OPTS="
ntfs:windows_names,fmask=133,dmask=022,recover
vfat:utf8
"

ONDD_SOCKET="/var/run/ondd.ctrl"
FSAL_SOCKET="/var/run/fsal.ctrl"

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

# Set the ONDD's output path to specified one
set_ondd_path() {
  path="$1"
  printf '<put uri="/output"><path>%s</path></put>\0' "$path" \
    > "$ONDD_SOCKET"
}

# Request FSAL index refresh
fsal_refresh() {
  printf '<request><command><type>refresh</type></command></request>\0' \
    > "$FSAL_SOCKET"
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
  mount -t "$ID_FS_TYPE" -o "$opts" "$DEVNAME" "$path"
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

# Log specified message and quit with non-0 return code
#
# The LED is truned off before exiting.
fail() {
  msg="$1"
  log "$msg"
  led_off
  exit 1
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

  # Now we start the real-deal mounting

  umountf "$TMPMOUNT"
  set_ondd_path "$PRIMARY_MPOINT"
  umount_ext

  log "Final mount to $EXTERNAL_MPOINT"
  mount_at "$EXTERNAL_MPOINT" "$opts" || fail "Unable to mount"

  log "Redirecting ONDD to external storage"
  set_ondd_path "$EXTERNAL_MPOINT"
  log "Refreshing file index"
  fsal_refresh
}

# Handle the 'remove' event
remove() {
  mpoint="$(get_mpoint)"
  if [ -z "$mpoint" ]; then
    log "$DEVNAME was not mounted, nothing to do"
    exit 0
  fi

  if [ "$mpoint" = "$EXTERNAL_MPOINT" ]; then
    log "Redirecting ONDD to internal storage"
    set_ondd_path "$PRIMARY_MPOINT"
  fi

  log "Attempting to unmount from '$mpoint'"
  # We cannot umount $DEVNAME here because the device node is already gone, so
  # we must unmount the mount point instead.
  umountf "$mpoint" || fail "Could not unmount the device"

  log "Refreshing file index"
  fsal_refresh
}

log "Handling hotplug even for $DEVNAME"

led_slow_blink
$ACTION  # functions match the action name
led_on
