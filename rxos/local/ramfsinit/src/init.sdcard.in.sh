#!/bin/sh
#
# This is the early userspace init script (or its template, depending on where 
# you are looking). The primary purpose of this script is to try and boot the
# rxOS userspace.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

export PATH=/bin

# Script parameters
TMPFS_SIZE="%TMPFS_SIZE%m"
VERSION="%VERSION%"
CMDLINE="$@"
OVERLAYS=
CONSOLE=/dev/console
ROOT_IMAGES="root.sqfs backup.sqfs factory.sqfs"

# Check whether command line has some argument
hasarg() {
  arg="$1"
  echo "$CMDLINE" | grep "$arg" > /dev/null 2>&1
}

# Echo given error message and drop into emergency shell
#
# The function will pause briefly so that prompt isn't swallowed by kernel
# messages.
bail() {
  msg=$*
  sleep 10
  echo "ERROR: $msg"
  echo "Dropping into emergency shell"
  export PS1="[rxOS emergency shell]# "
  exec sh
}

# Wait for /dev/mmcblk0p1 to appear
#
# Since we need the SD card to be present, we must wait for it to appear in the
# /dev directory. It is usually not necessary to wait too long, but it can 
# still happen that the device node is not present at this point (perhaps due 
# to some external device being plugged in).
wait_for_sd() {
  echo "Waiting for SD card to become available"
  while ! [ -e "/dev/mmcblk0p1" ]; do
    sleep 1
  done
}

# Check that specified path is an executable file or a link that points to one
test_exe() {
  path="$1"
  if [ -L "$path" ]; then
    test_exe "$(readlink -f "$path")"
    return $?
  fi
  [ -f "$path" ] && [ -x "$path" ]
}

# Return the overlay name by stripping the extension and prefix
overlay_basename() {
  overlay_path="$1"
  basename "${overlay_path%.*}" | cut -d- -f2
}

# Mount a SquashFS image on loopback device
loop_mount() {
  image="$1"
  mount_path="$2"
  [ -z "$image" ] && return 1
  [ -f "$image" ] || return 1
  mkdir -p "$mount_path" || return 1
  mount -t squashfs "$image" -o loop,ro "$mount_path" >/dev/null 2>&1
}

# Find a backup version of an overlay SquashFS image
find_backup() {
  name="$1"
  find /sdcard -name "overlay-${name}-*.sqfs.backup" | tail -n1
}

# Mount the root filesystem overlay
#
# Root filesystem overlays are SquashFS images that represent fragments of the
# root filesystem that are overlaid over the base root filesystem image and
# overrides parts of the base image or augment it.
#
# Every overlay is mounted under /overlays/<overlay_name>.
mount_overlay() {
  overlay_image="$1"
  overlay_name="$(overlay_basename "$overlay_image")"
  mount_path="/omnt/$overlay_name"
  if loop_mount "$overlay_image" "$mount_path"; then
    OVERLAYS="$OVERLAYS $mount_path"
    echo "Using overlay $overlay_name"
    return 0
  fi
  if loop_mount "$(find_backup "$overlay_name")" "$mount_path"
  then
    OVERLAYS="$OVERLAYS $mount_path"
    echo "Using overlay $overlay_name [BACKUP]"
    return 0
  fi
  echo "Corrupted overlay $overlay_name"
  return 1
}

# Mount the root filesystem
#
# The tmpfs is mounted with size specified by $TMPFS_SIZE, and overlaid over 
# the read-only rootfs image using OverlayFS to provide a volatile write 
# layer.
mount_root() {
  image_path="/sdcard/$1"
  echo "Attempt to mount $image_path"
  loop_mount "$image_path" "/rootfs" || return 1
  test_exe /rootfs/sbin/init || return 1
  lower="/rootfs"
  # Add any overlays
  for overlay in $OVERLAYS; do
    lower="$overlay:$lower"
  done
  mount -t overlay overlay \
    -o "lowerdir=$lower",upperdir=/tmpfs/upper,workdir=/tmpfs/work /root
}

# Set things up for switch_root
#
# Create the boot partition mount point in the target root filesystem, and move
# the SD card mount point to the new location.
#
# Also move the devtmpfs mount point into the root mount point.
set_up_boot() {
  mkdir -p /root/boot /root/dev
  mount --move /sdcard /root/boot
  mount --move /dev /root/dev
  mount --move /proc /root/proc
  mount --move /sys /root/sys
  [ "$SAFE_MODE" = y ] && touch /root/SAFEMODE
}

# Unount the root filesystem and related mounts
undo_root() {
  umount /root/boot 2>/dev/null
  umount /root/proc 2>/dev/null
  umount /root/dev 2>/dev/null
  umount /root 2>/dev/null
  umount /rootfs 2>/dev/null
}

# Boot into specified rootfs
doboot() {
  rootfs_image="$1"
  if hasarg noroot; then
    sleep 10
    echo "Do not boot into rootfs"
    exec $SH
  fi
  echo "Attempt boot $rootfs_image"
  set_up_boot
  exec switch_root /root /sbin/init $CMDLINE
}

###############################################################################
# SHOW STARTS HERE
###############################################################################

# Set the date to a sane value
date "2015-01-01 0:00:00"

# Populate the /dev, /proc, and /sys directories
mkdir -p /sys
mount -t devtmpfs devtmpfs /dev
mount -t proc proc /proc
mount -t sysfs sysfs /sys

# Setup console
exec 0<$CONSOLE
exec 1>$CONSOLE
exec 2>$CONSOLE

echo "++++ Starting rxOS v$VERSION ++++"

# Before the script can do its job, it needs to set up the mount points and 
# mount the root partition on the SD card. These mount points exist strictly 
# within the initial RAM filesystem and will be preserved after switch_root is 
# performed.
mkdir -p /sdcard /rootfs /tmpfs /root /omnt

# If 'shell' has been passed as a kernel command line argument, drop into
# emergency shell right away.
if hasarg "shell"; then
  sleep 10
  exec sh
fi

# If 'safemode' has been passed as a kernel command line argument, enable safe
# mode.
if hasarg "safemode"; then
  SAFE_MODE=y
fi

# Run setup hooks. The hooks are shell scripts that named like hook-*.sh. They
# are executed once (in a subshell) and they are expected to decide for
# themselves whether they need to run more than once. Because the hooks need to
# run as soon as possible (e.g., before any mounting has been performed), they
# are bundled in the initramfs and therefore cannot be removed or modified.
for hook in /hook-*.sh; do
  echo "Executing '$hook' hook"
  sh "$hook"
done

# Mount the tmpfs (RAM disk) to be used as a writable overlay, and set up
# directories that will be used for the overlays.
mount -t tmpfs tmpfs -o "size=$TMPFS_SIZE" /tmpfs || return 1
mkdir -p /tmpfs/upper /tmpfs/work 

# Wait for SD card if needed
[ -e "/dev/mmcblk0p1" ] || wait_for_sd

# Perform disk check on the SD card
fsck.vfat -yp /dev/mmcblk0p1

# We are ready to mount the boot partition. Since this partition is on a 
# removable medium, we use `-o errors=continue` to try and mount it at all 
# costs. Ideally we would have access to fsck.vfat here, but that (1) makes the 
# initial RAM filesystem image larger, and (2) it generally doen't help a whole
# lot in real life.
mount -t vfat -o errors=continue "/dev/mmcblk0p1" /sdcard \
  || bail "Failed to mount the SD card."

# Remove any .REC files created by fsck as those are usually completely useless
rm -f /sdcard/FSCK*.REC

# Remount SD card as read-only to prevent unnecessary writes (we allow this to 
# fail because we already have it mounted read-write which is good enough to 
# continue booting)
mount -o remount,ro,errors=continue "/dev/mmcblk0p1" /sdcard

# Mount overlay images if any
if [ "$SAFE_MODE" != y ]; then
  for overlay in /sdcard/overlay-*.sqfs; do
    mount_overlay "$overlay"
  done
fi

# The userspace is contained in SquashFS images. There are three such images on 
# the boot partition:
#
# - root.sqfs
# - backup.sqfs
# - factory.sqfs
#
# Initially, they are all identical. During the lifecycle of the receiver, OTA u
# updates will overwrite the first two leaving the last one intact. 
#
# The following block of code will attempt to boot each of the images in turn,
# and fall back on the factory.sqfs as last resort.
for rootfs_image in $ROOT_IMAGES; do
  if mount_root "$rootfs_image"; then
    doboot "$rootfs_image"
  fi
  # If we git this far, it means switch_root failed. We undo the set-up
  # performed in the preceeding code in order to allow for the next attempt (if
  # any).
  undo_root
done

# When no bootable root filesystem images are found, we drop into an emergency
# shell. We will pause a few seconds before we drop into shell, so that shell
# promp isn't interpolated into kernel messages.
bail "Could not find working boot image. SD card may be damaged."
