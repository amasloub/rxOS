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
  mkdir -p "$mount_path"
  mount -t squashfs "$overlay_image" -o loop,ro "$mount_path" \
    > /dev/null 2>&1 || return 1
  OVERLAYS="$OVERLAYS $mount_path"
  echo "Using overlay $overlay_name"
}

# Mount the root filesystem
#
# The tmpfs is mounted with size specified by $TMPFS_SIZE, and overlaid over 
# the read-only rootfs image using OverlayFS to provide a volatile write 
# layer.
mount_root() {
  mtdpart="$1"
  echo "Attempt to mount $image_path"
  mount -t ubifs -o ro "ubi0:$mtdpart" /root || return 1
  test_exe /rootfs/sbin/init || return 1
  lower="lowerdir=/rootfs"
  # Add any overlays
  for overlay in $OVERLAYS; do
    lower="$lower:$overlay"
  done
  mount -t overlay overlay \
    -o "$lower",upperdir=/tmpfs/upper,workdir=/tmpfs/work /root
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

# Populate the /dev and /proc directories
mount -t devtmpfs devtmpfs /dev
mount -t proc proc /proc

# Setup console
exec 0<$CONSOLE
exec 1>$CONSOLE
exec 2>$CONSOLE

echo "++++ Starting rxOS v$VERSION ++++"

# Before the script can do its job, it needs to set up the mount points and 
# mount the root partition on the SD card. These mount points exist strictly 
# within the initial RAM filesystem and will be preserved after switch_root is 
# performed.
mkdir -p /sdcard /rootfs /tmpfs /root /overlays /omnt

# If 'shell' has been passed as a kernel command line argument, drop into
# emergency shell right away.
if hasarg "shell"; then
  sleep 10
  exec sh
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

# TODO: mount -t ubi -o ro ubi0:overlay /overlays
# We can't do that yet cause there's no ubi volume for overlay. This should be
# provided by a boot hook.
for overlay in /overlays/overlay-*.sqfs; do
  mount_overlay "$overlay"
done

# The userspace is contained in SquashFS images. There are three such images on 
# the boot partition:
#
# - root.sqfs
# - failsafe.sqfs
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
