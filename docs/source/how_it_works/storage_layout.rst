Storage layout
==============

rxOS storage is highly compartmentalized to allow different pieces of the
system and application code to utilize different portions of the storage
without stepping on each other. There are two types of storage used by rxOS:

- SD card (on Raspberry Pi)
- NAND flash (on CHIP)

The following table shows different portions of the storage on SD card and how
they are used:

+-----------------------+-------+-----------+---------------------------------+
| Storage device        | Size  | Format    | Usage                           |
+===+===================+=======+===========+=================================+
| 1 | Primary partition | 200M  | FAT32     | `Boot files`_                   |
+---+-------------------+-------+-----------+---------------------------------+
| 2 | Extended partition                    | `Receiver state`_               |
+---+-------------------+-------+-----------+---------------------------------+
| 5 | conf              | 24M   | ext4      | Persistent system configuration |
+---+-------------------+-------+-----------+---------------------------------+
| 6 | cache             | 600M  | ext4      | Download cache                  |
+---+-------------------+-------+-----------+---------------------------------+
| 7 | data              | 2G    | ext4      | Application data                |
+---+-------------------+-------+-----------+---------------------------------+
| 8 | downloads         | rest  | ext4      | Downloaded files                |
+---+-------------------+-------+-----------+---------------------------------+

The following table shows different portions of the NAND flash storage and how
they are used:

+-----------------------+-------+-----------+---------------------------------+
| Storage device        | Size  | Format    | Usage                           |
+===+===================+=======+===========+=================================+
| 1 | spl               | 4M    | raw       | Secondary program loader        |
+---+-------------------+-------+-----------+---------------------------------+
| 2 | spl-backup        | 4M    | raw       | SPL backup                      |
+---+-------------------+-------+-----------+---------------------------------+
| 3 | uboot             | 4M    | raw       | U-Boot Bootloader               |
+---+-------------------+-------+-----------+---------------------------------+
| 4 | env               | 4M    | raw       | Bootloader settings             |
+---+-------------------+-------+-----------+---------------------------------+
| 5 | UBI                                   | Kernel and `Receiver state`_    |
+---+-------------------+-------+-----------+---------------------------------+
| 1 | linux             | 64M   | ubifs     | `Boot files`_                   |
+---+-------------------+-------+-----------+---------------------------------+
| 2 | root              | 128M  | ubifs     | Root filesytem                  |
+---+-------------------+-------+-----------+---------------------------------+
| 3 | root-backup       | 128M  | ubifs     | Backup root filesystem          |
+---+-------------------+-------+-----------+---------------------------------+
| 4 | conf              | 64M   | ubifs     | Persistent configuration        |
+---+-------------------+-------+-----------+---------------------------------+
| 5 | cache             | 600M  | ubifs     | Download cache                  |
+---+-------------------+-------+-----------+---------------------------------+
| 6 | appdata           | 1G    | ubifs     | Application data                |
+---+-------------------+-------+-----------+---------------------------------+
| 7 | data              | rest  | ubifs     | Downloaded files                |
+---+-------------------+-------+-----------+---------------------------------+


Boot files
----------

Stores the boot files. 

On Raspberry Pi, it contains the following files:

- Raspberry Pi 3 binary device tree
- Stage 2 and 3 bootloader
- ``start.elf``
- Kernel image (``kernel.img``)
- Main and fallback rootfs SquashFS images (``root.sqfs``, ``fallback.sqfs``)
- Factory default SquashFS image (``factory.sqfs``)

On CHIP, it contains the following files:

- CHIP binary device tree
- Kernel image (``zImage``)

These files are read-only (except when updating the system).

Receiver state
--------------

The receiver state extended partition is split into 4 logical partitions. These
partitions contain:

- persistent system configuration
- download cache
- application data
- downloads

Persistent system configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The init script that sets up configuration overrides maintains a list of
configuration files that should be overridden based on the contents of the
config partition. The files from the config partition are symlinked to
appropriate locations in the rootfs.

Download cache
^^^^^^^^^^^^^^

The download cache is a storage area for partial downloads. ONDD download cache
is stored in a separate partition to maximize control over the storage
capacity.

Application data
^^^^^^^^^^^^^^^^

Application data partition stores application configuration, databases, and
other application state.

Downloaded files
^^^^^^^^^^^^^^^^

Remaining space on the SD card is used for permanent storage of downloaded
files.
