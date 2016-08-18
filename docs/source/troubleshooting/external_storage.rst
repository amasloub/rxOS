External storage issues
=======================

This section describes possible issues related to external storage support, and
also provides general troubleshooting tips.

Storage does not mount
----------------------

If storage simply does not mount, ensure that it is one of the supported
formats (see :doc:`../how_it_works/external_storage`) and that the files are
accessible on a computer. If your USB stick or memory card is
factory-formatted, check that it is FAT32 and not exFAT (exFAT is common with
large capacity sticks and cards, larger than 64GB).

For NTFS filesystem, there is no integrity check on mount, so ensure that the
disk is checked on a Windows computer prior to use.

FSCK*.REC files appearing on storage after use
----------------------------------------------

The integrity check for FAT32 system may create ``FSCK*.REC`` files (where
``*`` is a sequence of four digits). These files represent recovered orphan
file data. It is usually safe to remove them.

External storage files are not present in the file list
-------------------------------------------------------

Files not appearing shortly after plugging in an external storage is normal.
External storage devices have to be scanned for new files, and this scan may
take up to several minutes. The time it takes to scan the disk depends on such
factors as storage device perofrmance and the number of files (not their size).

If the new files do not appear even after an hour of waiting, try restarting
the receiver.

.. warning::
    Dot not remove and reattach the disk multiple times in in quick succession
    as this will cause multiple scanning to be triggered and will take even
    longer to index the disk.

Wrong partition mounted
-----------------------

Currently, only one partition can be used from multi-partition disk, and this
is the last partition with supported partition format (see
:doc:`../how_it_works/external_storage`).

General troubleshooting
-----------------------

This subsection contains instructions useful for general troubleshooting of
storage-related issues.

Testing the hotplug script
^^^^^^^^^^^^^^^^^^^^^^^^^^

The hotplug script, although a shell script, is not meant to be run from the
shell. It is executed by udev, and expects to see some of the udev environment
variables. However, it is still possible to run the script manually by
simulating the udev environment.

The following environment variables are expected:

- ``ACTION``: 'add' or 'remove', tells the script whether the device was
  attached or detatched
- ``DEVNAME``: device node (e.g., /dev/sda1)
- ``ID_FS_TYPE``: disk format (vfat, ntfs, ext2, ext3, or ext4)
- ``ID_BUS``: must be 'usb'

Here is an example simulating a hot-plug event for ``/dev/sdb1`` device with
``ntfs`` disk format::

    $ sudo su
    Password: ********
    # ACTION=add DEVNAME=/dev/sdb1 ID_FS_TYPE=ntfs ID_BUS=usb \
        /usr/sbin/hotplug.storage

Troubleshooting storage issues
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If storage does not appear to be used after plugging in, it is recommended that
integrity check is performed on a computer.

Restarting the receiver may also help in some cases.

The system logs at ``/var/log/messages`` contain messages with more information
about the nature of failure. To get the storage hotplug logs, log in using SSH
(see :doc:`../how_it_works/remote_access`) and execute the following command::

    $ grep hotplug.sd /var/log/messages
    Jan  1 00:21:21 rxos user.notice hotplug.sda: Handling hotplug even for /dev/sda
    Jan  1 00:21:21 rxos user.notice hotplug.sda: Attempting to use iso9660 disk /dev/sda
    Jan  1 00:21:21 rxos user.notice hotplug.sda: iso9660 is not a supported filesystem.
    Jan  1 00:21:21 rxos user.notice hotplug.sda1: Handling hotplug even for /dev/sda1
    Jan  1 00:21:21 rxos user.notice hotplug.sda1: Attempting to use vfat disk /dev/sda1
    Jan  1 00:21:22 rxos user.notice hotplug.sda1: Checking disk integrity 
    Jan  1 00:21:22 rxos user.notice hotplug.sda1: Mounting with options: 'utf8'
    Jan  1 00:21:22 rxos user.notice hotplug.sda1: Doing a trial mount on /mnt/sda1
    Jan  1 00:21:22 rxos user.notice hotplug.sda1: Final mount to /mnt/external
    Jan  1 00:21:22 rxos user.notice hotplug.sda1: Redirecting ONDD to external storage
    Jan  1 00:21:22 rxos user.notice hotplug.sda1: Refreshing file index

