The boot process
================

The boot process is divided into 3 stages:

- Hardware boot
- Early userspace init
- Userspace init

Storage contents
----------------

The are two types of storage devices used in rxOS, based on the target device.
On Raspberry Pi, SD cards are used, while on CHIP, the built-in NAND flash
storage is used.

SD card boot partition contents
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

NAND contents
~~~~~~~~~~~~~

The NAND contains the following:

- SPL (secondary program loader) partition
- SPL backup partition
- U-Boot bootloader partition
- U-Boot bootloader environment partition
- boot partition
    - kernel image (``zImage``)
    - device tree blob (``sun5i-r8-chip.dtb``)
- root filesystem partition
- backup root filesystem partition
- data partitions

Hardware boot
-------------

Before any of the rxOS-specific software is executed, there is a phase in which
the base hardware is initialized and the hardware-specific bootloaders are run.

Raspberry Pi boot
~~~~~~~~~~~~~~~~~

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

CHIP boot
~~~~~~~~~

When the board receives power, code in the boot rom (BROM) is executed. This
code will activate a small amount of memory and load SPL from either the first
NAND partition or its backup image on the second partition.

SPL's job is to activate all of DRAM and load the U-Boot bootloader from the
third partition.

When U-Boot is activated it reads the boot parameters from the U-Boot
environment partition. By default, this will cause U-Boot to mount the boot
partition (labelled 'linux'), and load the kernel image and the DTB from it.

Finally, the kernel image is executed.

The early userspace
-------------------

Early userspace initialization happens within the ``init`` script in the root
of the kernel's initramfs. We will refer to this script as EI for brevity
(early init).

EI is generated from a template found in ``rxos/initramfs/init.*.in.sh`` file.
The asterix in the name can be either 'nand' or 'sdcard' depending on the
target platform. The sources are thoroughly documented, so if you need to know
more than what's presented here, you are welcome to peruse the sources.

It first mounts devtmpfs to ``/dev`` so that device nodes are accessible. It
then mounts the boot partition in order to access root filesystem
images/partitions.

On Raspberry Pi, additional data partitions are created. For NAND-based boot,
this step is skipped because the extra partitions are programmed along with the
base system when the NAND is flashed at the factory.

On Raspberry Pi, there are three possible candidates for the final userspace,
and those are ``root.sqfs``, ``backup.sqfs``, and ``factory.sqfs``.  On CHIP,
there are two possible candidates, ``ubi0:root`` and ``ubi0:root-backup``.

A RAM disk with size configurable at build-time (default is 80 MiB) is created
to serve as a write-enabled overlay over the read-only root filesystem. The
mount points for the SD card and devtmpfs are moved to ``/boot`` and ``/dev``
in the target rootfs, respectively.

If overlay SquashFS images are found (named ``overlay-<name>.sqfs``), they are
laid over the root filesystem to provide device-specific extension.

For each candidate root filesystem, EI mounts the image, and creates a write
overlay using OverlayFS and the previously configured RAM disk. It then
attempts to switch to the new root filesystem using BusyBox's ``switch_root``
command which executes the ``/sbin/init`` binary in the target root filesystem.

If the switch is successful, early userspace initialization is complete and the
userspace proper takes over.

If the switch is not successful, the next candidate is tried until no root
filesystem candidates are left. If none of the root filesystem
images/partitions can be booted, EI starts an emergency shell where
troubleshooting can be performed.

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
lexical file name order.

The userspace will start the WiFi hotspot, web and database servers, and
Outernet applications. Any attached external storage devices will also be
mounted during this stage.
