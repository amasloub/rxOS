#!/busybox sh

# This is the early userspace init script (or its template, depending on where 
# you are looking). The primary purpose of this script is to try and boot the
# rxOS userspace.

# Script parameters
TMPFS_SIZE="%TMPFS_SIZE%m"
VERSION="%VERSION%"
ROOT_IMAGES="root.sqfs backup.sqfs factory.sqfs"

# Command aliases
BB="/busybox"
MKDIR="$BB mkdir"
MOUNT="$BB mount"
READLINK="$BB readlink"
SLEEP="$BB sleep"
SH="$BB sh"
SWITCH_ROOT="$BB switch_root"
UMOUNT="$BB umount"

# Echo given error message and drop into emergency shell
#
# The function will pause briefly so that prompt isn't swallowed by kernel
# messages.
bail() {
  msg=$*
  $SLEEP 10
  echo "ERROR: $msg"
  echo "Dropping into emergency shell"
  export PS1="[rxOS emergency shell]# "
  exec $SH
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
    $SLEEP 1
  done
}

# Check that specified path is an executable file or a link that points to one
test_exe() {
  path="$1"
  if [ -L "$path" ]; then
    test_exe "$($READLINK -f "$path")"
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
  $MOUNT -t squashfs "$image_path" -o loop,ro /rootfs || return 1
  test_exe /rootfs/sbin/init || return 1
  $MOUNT -t overlay overlay \
    -o lowerdir=/rootfs,upperdir=/tmpfs/upper,workdir=/tmpfs/work /root
}

# Set things up for switch_root
#
# Create the boot partition mount point in the target root filesystem, and move
# the SD card mount point to the new location.
set_up_boot() {
  $MKDIR -p /mnt/root/boot
  $MOUNT --move /mnt/sdcard /mnt/root/boot
}

# Unount the root filesystem and related mounts
undo_root() {
  $UMOUNT /mnt/root/boot 2>/dev/null
  $UMOUNT /mnt/root 2>/dev/null
  $UMOUNT /mnt/rootfs 2>/dev/null
}

###############################################################################
# SHOW STARTS HERE
###############################################################################

# Populate the /dev directory
$MOUNT -t devtmpfs devtmpfs /dev

# Setup console
exec 0</dev/console
exec 1>/dev/console
exec 2>/dev/console

echo "++++ Starting rxOS v$VERSION ++++"

# Before the script can do its job, it needs to set up the mount points and 
# mount the root partition on the SD card. These mount points exist strictly 
# within the initial RAM filesystem and will be preserved after switch_root is 
# performed.
$MKDIR -p /sdcard /rootfs /tmpfs /root

# Mount the tmpfs (RAM disk) to be used as a writable overlay, and set up
# directories that will be used for the overlays.
$MOUNT -t tmpfs tmpfs -o "size=$TMPFS_SIZE" /tmpfs || return 1
$MKDIR -p /tmpfs/upper /tmpfs/work 

# Wait for SD card if needed
[ -e "/dev/mmcblk0p1" ] || wait_for_sd

# We are ready to mount the boot partition. Since this partition is on a 
# removable medium, we use `-o errors=continue` to try and mount it at all 
# costs. Ideally we would have access to fsck.vfat here, but that (1) makes the 
# initial RAM filesystem image larger, and (2) it generally doen't help a whole
# lot in real life.
if ! $MOUNT -t vfat -o errors=continue "/dev/mmcblk0p1" /sdcard; then
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
    echo "Attempt boot $rootfs_image"
    exec $SWITCH_ROOT /root /sbin/init $@
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
