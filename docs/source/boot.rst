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

- Raspberry Pi stage 2 bootloader (``bootcode.bin``)
- Raspberry Pi stage 3 bootloader (``start.elf``)
- Raspberry Pi fixup data (``fixup.dat``)
- device tree blob (``bcm2710-rpi-3-b.dtb``)
- kernel image with early userspace (``kernel.img``)
- main root filesystem image (``root.sqfs``)
- backup root filesystem image (``backup.sqfs``)
- original factory root filesystem image (``factory.sqfs``)

Raspberry Pi boot
-----------------

The first stage is the same for all Raspberry Pi devices, but it will be
described here for completeness.

The ROM on the Raspberry Pi board contains the stage 1 bootloader (S1). When
power is applied, VideoCore GPU is activated, and S1 is executed on a small
RISC core that is present on the board. The S1 bootloader mounts the SD card,
and loads S2, ``bootcode.bin``, into the GPU's L2 cache and executes it on the
GPU.

S2 activates the SDRAM. It also understands ELF binaries, and loads S3,
``start.elf``, from the SD card. S3 is also known as GPU firmware, and this is
what causes the rainbow splash (4 pixels that are blown up to full-scren) to be
displayed.

.. note::
    If there is a rainbow splash on the screen but no further activity, it
    means that S3 has been loaded successfully but kernel image did not boot.

S3 reads the firmware configuration file ``config.txt`` (if any), and then
proceeds to split the RAM between GPU and ARM CPU. S3 also loads a file called
``cmdline.txt`` if it exists, and will pass its contents as kernel command
line. S3 finally enables the ARM CPU and loads the kernel image (``kernel.img``
by default, configurable via ``config.txt``), which is executed on the ARM CPU.

.. note::
    ``start.elf`` is actually a complete proprietary operating system known as
    VCOS (VideoCore OS).

The kernel image contains a minimal early userspace and its ``init`` script is
executed.

The early userspace
-------------------

Early userspace initialization happens within the ``init`` script in the root
of the kernel's initramfs. We will refer to this script as EI for brevity
(early init).

EI is generated from a template found in ``rxos/initramfs/init.in.sh`` file.
The sources are thoroughly documented, so if you need to know more than what's
presented here, you are welcome to peruse the sources.

EI starts between 3 and 5 seconds after kernel starts booting. It mounts the SD
card in order to access root filesystem images. There are three possible
candidates for the final userspace, and those are ``root.sqfs``,
``backup.sqfs``, and ``factory.sqfs``. These images are LZ4-compressed SquashFS
images that contain the userspace executables, code, and data.

A RAM disk with size configurable at build-time (default is 80 MiB) is created
to serve as a write-enabled overlay over the read-only root filesystem. 

For each candidate root filesystem, EI mounts the image, and creates a write
overlay using Overlay FS and the previously configured RAM disk. It then
attempts to switch to the new root filesystem using BusyBox's ``switch_root``
command which executes the ``/sbin/init`` binary in the target root filesystem.

If the switch is successful, early userspace initialization is complete and the
userspace proper takes over.

If the switch is not successful, the next candidate is tried until no root
filesystem candidates are left. If none of the root filesystem images can be
booted, EI starts an emergency shell where troubleshooting can be performed.

.. note::
    Even if switch is successful, it does not mean the boot will succeed.
    Minimal checking is performed to ensure that the root filesystem contains a
    path ``/sbin/init`` which an executable file or a symlink pointing to one,
    but nothing beyond that is done. If the executable fails or does something
    that terminates the init process, kernel **will** panic and boot will fail.
    In general, however, this is not quite realistic as long as valid images
    built for rxOS are used.

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

2. The logical partitions are mounted:

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
