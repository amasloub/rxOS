OTA updates
===========

rxOS supports secure automatic over-the-air updates (OTA updates).

When updated firmware is delivered into ``/updates/<platform name>/``
directory, it is passed to ``pkgtool`` which is an update package verfication
tool. The update package contains the payload files, executable script
(installer script) that controls the update process, and a signature. The
signature is checked by the ``pkgtool`` to ensure the authenticity of the
update package. Once the package is verified, the installer script is executed.

The installer script may contain arbitrary code, so udpate is just one of the
many things it can be configured to do. In this section, we will discuss a
typical update process.

Normally, the payload for an update pakage consits of the root filesystem image
and one or more of the optional extras:

- the pre-install script
- the post-install script
- kernel image
- DTB file
- firmware
- bootloader
- device-specific overlays

The update starts with a version check. If the version of the receiver's
firmware is the same or newer than the version of the payload, installer aborts
the update.

If pre-install script is present, it is executed first.

Next the payload is copied or flashed into appropriate location. 

On CHIP, the root filesystem is flashed to its backup UBI volume and then the
names of the backup and main root filesystem volumes are swapped, so that the
new root filesystem will get mounted on boot.

On Raspberry Pi 3, the root filesystem is copied into the boot partition just
like the kernel image.

Once the installation is finished, the post-install script, if present, is
invoked. This script performs any one-time adjustments to the system before
reboot.

The system is finally rebooted to complete the update.

This entire process happens automatically without user intervention.
