Storage layout
==============

Outerbox 2 storage is highly compartmentalized to allow different pieces of the
system and application code to utilize different portions of the storage
without stepping on each other. The following table shows different portions of
the storage and how they are used:

+-----------------------+-------+-----------+---------------------------------+
| Storage device        | Size  | Format    | Usage                           |
+=======================+=======+===========+=================================+
| SD partition 1        | 400M  | FAT32     | `Boot files`_                   |
+-----------------------+-------+-----------+---------------------------------+
| SD extended partition                     | `Receiver state`_               |
+---+-------------------+-------+-----------+---------------------------------+
| 5 | config            | 24M   | ext4      | Persistent system configuration |
+---+-------------------+-------+-----------+---------------------------------+
| 6 | cache             | 600M  | ext4      | Download cache                  |
+---+-------------------+-------+-----------+---------------------------------+
| 7 | appdata           | 1024M | ext4      | Application data                |
+---+-------------------+-------+-----------+---------------------------------+
| 8 | downloads         | rest  | ext4      | Downloaded files                |
+---+-------------------+-------+-----------+---------------------------------+

Boot files
----------

Stores the boot files. It contains the following files:

- Raspberry Pi 3 binary device tree
- Stage 2 and 3 bootloader
- ``start.elf``
- Kernel image (``zImage``)
- Main and fallback rootfs SquashFS images (``root.sqfs``, ``fallback.sqfs``)
- Factory default SquashFS image (``factory.sqfs``)

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
