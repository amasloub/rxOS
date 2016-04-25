OTA updates
===========

Outerbox 2 supports secure automatic over-the-air updates (OTA updates). 

When the OTA update package arrives, it is checked for authenticity. The update
packages are digitally signed and checked against the public key stored on the
receiver. Once the authenticity check passes, the update package is installed.

The update package contains the following files:

- the pre-install script
- the installer script
- the post-install script
- rootfs image in SquashFS format
- SHA1 hash of the rootfs image

When the installation begins, the pre-install script is invoked. It runs in a
shell with root privileges and has access to the currently running system. It
performs any tasks necessary to prime the system for installation.

The installer unpacks the rootfs image and copies it over the main rootfs image
and the failsafe rootfs image on the SD card. The rootfs images are written
like so:

1. A copy of the existing rootfs image is created in ``/tmp`` (this is in
   tmpfs)
2. The bundled rootfs image is overwritten over the existing one.
3. ``sync`` is called to flush any unwritten pages
4. SHA1 hexdigest of the newly written rootfs image is compared to the hash in
   the update package
5. If the hashes match, the operation is considered complete, and if the hashes
   do not match, the copy of the rootfs is restored and the update is aborted

Once the installation is finished, the post-install script is invoked in a
shell with root privileges. This script performs any one-time adjustments to
the system before reboot.

When post-install script finishes, the system is rebooted.
