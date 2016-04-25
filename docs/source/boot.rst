The boot process
================

The boot process is divided into 3 stages:

- Raspberry Pi boot
- Early userspace init
- Userspace init

SD card boot partition contents
-------------------------------

The first partition of the SD card is a 400MB FAT32 partition with the
following contents:

- Raspberry Pi stage 2 and 3 bootloaders
- ``start.elf``
- device tree blobs
- kernel image (``zImage``)
- two identical rootfs images (``root.sqfs``, ``fallback.sqfs``)
- original factory rootfs image (``factory.sqfs``)

Raspberry Pi boot
-----------------

The first stage is the same for all Raspberry Pi devices, but it will be
described here for completeness.

1. When power is applied, GPU is activated
2. Stage 1 bootloader is loaded from the ROM into the L2 cache and mounts the
   SD card
3. Stage 2 bootloader (``bootcode.bin``) is loaded from the SD card and
   activates SDRAM
4. Stage 3 bootloader (``loader.bin``) is loaded from the SD card and loads
   start.elf
5. ``start.elf`` loads ``cmdline.txt`` and ``config.txt`` files, the DTBs, the
   kernel image
6. ARM CPU is activated
7. Kernel is is executed on the CPU
8. The ``init`` script in the kernel's initramfs is executed

The early userspace
-------------------

Early userspace initialization happens within the ``init`` script in the root
of the kernel's initramfs.

1. Init mounts the SD card
2. The first of two rootfs images is mounted as root filesystem
3. A 100MB ramdisk is created and overlaid over the read-only root filesystem
   using union mount.
4. All mount points created in the early userspace are moved to the ``mnt``
   directory inside the root filesystem
5. ``switch_root`` is performed to attempt a boot from the rootfs
6. If either step 3 or 5 fail, the process is repeated from step 2 using the
   second (fallback) rootfs image
7. If either step 3 or 5 fail for the fallback image, an image called
   ``factory.sqfs`` is used as final attempt to boot the system
8. The ``init`` binary from the rootfs is executed

The userspace
-------------

Userspace initialization happens in the rootfs and is carried out by the init
scripts in ``/etc/init.d``. The init scripts are executed synchronously in the
lexical file name order. This subsection provides an overview of the
initialization but not a description of what each of the scripts does.

1. First the SD card is probed for existence of an extended partition, and one
   is created if not found, with the following logical partitions:

   - 5: 24MB ext4 partition for storing system file overrides
   - 6: 600MB download cache partition
   - 7: 1024MB application data partition
   - 8: remaining unallocated space

2. The extra partitions are mounted to:

   - partition 5 to ``/mnt/config``
   - partition 6 to ``/mnt/cache``
   - partition 7 to ``/mnt/appdata``
   - partition 8 to ``/mnt/downloads``

3. Files listed in persist list are symlinked from ``/mnt/config`` to
   appropriate parts of the root filesystem, overriding the read-only files
   found in the rootfs image (e.g., ``/etc/shadow``, network configuration, 
   etc)
4. Lower-level system services are started (networking, SSH server, FTP server,
   HTTP server)
5. Applications are started (ONDD, FSAL, Librarian)
