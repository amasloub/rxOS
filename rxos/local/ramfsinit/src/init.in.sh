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
ROOT_IMAGES="root.sqfs backup.sqfs factory.sqfs"
CMDLINE="$@"

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

# Mount the root filesystem
#
# The tmpfs is mounted with size specified by $TMPFS_SIZE, and overlaid over 
# the read-only rootfs image using OverlayFS to provide a volatile write 
# layer.
mount_root() {
  image_path="/sdcard/$1"
  echo "Attempt to mount $image_path"
  mount -t squashfs "$image_path" -o loop,ro /rootfs || return 1
  test_exe /rootfs/sbin/init || return 1
  mount -t overlay overlay \
    -o lowerdir=/rootfs,upperdir=/tmpfs/upper,workdir=/tmpfs/work /root
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
exec 0</dev/console
exec 1>/dev/console
exec 2>/dev/console

echo "++++ Starting rxOS v$VERSION ++++"

# Before the script can do its job, it needs to set up the mount points and 
# mount the root partition on the SD card. These mount points exist strictly 
# within the initial RAM filesystem and will be preserved after switch_root is 
# performed.
mkdir -p /sdcard /rootfs /tmpfs /root

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

# Wait for SD card if needed
[ -e "/dev/mmcblk0p1" ] || wait_for_sd

# We are ready to mount the boot partition. Since this partition is on a 
# removable medium, we use `-o errors=continue` to try and mount it at all 
# costs. Ideally we would have access to fsck.vfat here, but that (1) makes the 
# initial RAM filesystem image larger, and (2) it generally doen't help a whole
# lot in real life.
if ! mount -t vfat -o errors=continue "/dev/mmcblk0p1" /sdcard; then
  bail "Failed to mount the SD card."
fi

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
