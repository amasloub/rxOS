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
CMDLINE="$*"
OVERLAYS=
CONSOLE=/dev/console
ROOT_PARTS="root root-backup"
SAFE_MODE_PIN=1016

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
  find /linux -name "overlay-${name}-*.sqfs.backup" | tail -n1
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
  volname="$1"
  echo "Attempt to mount ubi0:$volname"
  mount -t ubifs -o ro "ubi0:$volname" /rootfs || return 1
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
  mount --move /linux /root/boot
  mount --move /dev /root/dev
  mount --move /proc /root/proc
  mount --move /sys /root/sys
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
    exec sh
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

# Populate the /dev and /proc directories
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
mkdir -p /rootfs /tmpfs /root /linux /omnt

# If 'shell' has been passed as a kernel command line argument, drop into
# emergency shell right away.
if hasarg "shell"; then
  sleep 10
  exec sh
fi

# Determine whether we are using safe mode or not by checking the SAFE_MODE_PIN
# value and presence of safemode command line argument
echo "$SAFE_MODE_PIN" > /sys/class/gpio/export
is_safe_mode=$(cat "/sys/class/gpio/gpio$SAFE_MODE_PIN/value")
echo "$SAFE_MODE_PIN" > /sys/class/gpio/unexport
if hasarg "safemode" || [ "$is_safe_mode" = 0 ]; then
  SKIP_OVERLAYS=y
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

# Mount overlay images if any
mount -t ubifs -o ro ubi0:linux /linux
if [ "$SKIP_OVERLAYS" != y ]; then
  for overlay in /linux/overlay-*.sqfs; do
    mount_overlay "$overlay"
  done
fi

# The userspace is contained on one of two MTD partitions. These are:
#
# - root
# - root-backup
#
# The following block of code will attempt to boot each of the partitions in 
# turn, and fall back on the factory.sqfs as last resort.
for rootfs_image in $ROOT_PARTS; do
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
