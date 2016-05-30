Using external storage devices
==============================

Over time, the storage on the SD card may become full. rxOS supports using
external storage devices via the USB ports. Only one external storage device
can be used at a time.

The following table shows the supported disk formats and their characteristics.

==============  =================  ===============  ===========================
format          integrity check    large disks      power failure recovery
==============  =================  ===============  ===========================
FAT32           Yes                No               No
NTFS            No                 Yes              Yes
ext2 [1]_       Yes                Yes              No
ext3 [1]_       Yes                Yes              Yes
ext4 [1]_       Yes                Yes              Yes
==============  =================  ===============  ===========================

FAT32 is the most common disk format for USB sticks and external hard drives.
Although exFAT is becoming more common with large-capacity devices, it is not
supported by rxOS, so such devices should be reformatted using the NTFS format
(FAT32 formatting on Windows does not support large disks).

Linux users may use ext2, ext3 or ext4 format in addition to the other two.

Integrity check is prerformed on the disk where supported and an attempt is
made to fix any problems with the on-disk data. While FAT32 supports integrity
checking, it is not as complete as running disk checks on Windows machines.

.. [1] Creation of disks in this format is only supported on Linux operating
       systems

Connecting an extrnal storage device
------------------------------------

External storage devices can be simply plugged into one of the available USB
ports.

.. warning::
    Some external storage devices (and especially mechanical USB hard disks)
    draw a lot of electrical current from the USB port and may cause Raspberry
    Pi to shut down. In such cases, a powered USB hub will be required.

When the storage device is plugged in, it is checked for format. If the device
uses an unsupported format, it is not used and may be safely unplugged.

rxOS then mounts the disk to a temporary location to test that it can be
mounted. If the test mount fails, the disk is ignored and not used as external
storage.

When the test mount is successful, rxOS will mount the disk as external storage
and will redirect downloads to it.

Once the disk is mounted, reindexing of the content is started, and any content
that already existed on the attached disk becomes available after a while.

.. note::
    Although it is possible to attach more than one storage device, only the
    last-attached device is used as external storage. The other storage device
    is unmounted and may be unplugged.

Disconnecting the external storage device
-----------------------------------------

External storage devices may be simply disconnected. Unmounting is done after
the fact, unless the user interface provides support for unmounting.

When a disk is disconnected, downloads are redirected to the internal storage
on the SD card, and reindexing is started. Any files that were present on the
external storage device become unavailable afer a while.

Status LED indication
---------------------

During storage hot-plug events, the status LED (green) indicates the status of
the hot-plugging. 

**LED blinking slowly** (0.5s interval) indicates that the storage mounting has
started.

**LED blinking fast** (0.1s interval) indicates that the integrity check has
started.

**LED solid** indicates that the storage device was mounted.

**LED off** indicates that the storage device was not mounted due to an error.
