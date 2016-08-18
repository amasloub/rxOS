The early userspace
===================

The early userspace consists of an init script and a minimal set of libraries
and programs necessary to prepare the system for the proper userspace
initialization. 

The early userspace is built by enabling the "User-provided options > System
configuration > Create early userspace cpio archive" option. This option is
defined by a local package called ``ramfsinit``. The package contains the file
list for the early userspace and the init script template.

During the early userspace initialization, the SD card's boot partition is
mounted. If the card contains any one-time boot hooks, those are executed and
immediately removed. The root filesystem images are found, and mounted, and the
init script finally switches to the mounted root filesystem (userspace proper).
If no mountable root filesystem images are found, init script drops into an
emergency shell.

Boot hooks
----------

Boot hooks are scripts in the early userspace image that perform pre-boot
setup. One example of such a hook is the ``selfpartition`` hook (provided by
``boothook-selfpartition`` local package) which prepares the data persistence 
partitions on the Raspberry Pi SD card. 

Hooks are looked up by ``hook-*.sh`` name pattern and are executed in a
subshell every time rxOS boots. It is the hook script's job to determine wither
they need to take action or not.

You can read more about boot hooks in :doc:`boot_hooks`.

Mounting the rootfs
-------------------

On the SD card there are three root filesystem images. The ``rootfs.sqfs`` is
the default root filesystem image. ``backup.sqfs`` is the same image as the
default one, and serves as a backup in case the first image is corrupted or OTA
update fails. Lastly, the ``factory.sqfs`` serves as a fallback image. The
latter remains the same throughout the device's useful life (factory state).

Root filesystem images are loop-mounted read-only and are overlaid with a RAM
disk that provides the write layer. This provides protection against corruption
resulting from partial writes and allows the user to reset the device to a
known state by power-cycling it.

The situation is similar for NAND flash, but the root filesystem is stored as
UBI volumes, and there are only two copies.

Emergency shell
---------------

Emergency shell is a minimal shell that can be used when troubleshooting boot
issues. This is not a fully featured environment such as the one typically
found in desktop Linux distributions, so many familiar commands are missing
(e.g., no ``lspci``, ``lsusb``, ``htop``, etc). All commands are available
through the ``busybox`` binary at the root of the early userspace RAM disk.
`Busybox documentation <https://busybox.net/downloads/BusyBox.html>`_ describes
these commands (called 'applets'), but one should have in mind that not all
Busybox features are enabled.
