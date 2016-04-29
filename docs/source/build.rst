Building the firmware image
===========================

The build is broadly divided into three parts that are carried out in one
sequence, driven by Buildroot.

- Linux kernel compilation
- Rootfs compilation
- Early userspace and kernel recompilation

During Linux kernel compilation, a kernel image is compiled with a dummy
initramfs image (just an empty file). Following the kernel, the root filesystem
contents are compiled. Finally, the cpio archive for the early userspace is
created and linked into the kernel image.

In order to build the firmware, you should be familiar with `Buildroot
<http://www.buildroot.org/docs.html>`_.

The build is initated by invoking ``make`` or ``make build``.

To completely clean up the build and restart it from scratch, use ``make clean
build``. It is generally not needed to do this, though. In most cases, a more
efficient alternative is to call ``make rebuild-everything``..

To customize the build use ``make menuconfig``, which brings up the Buildroot's
configuration menu.

Linux kernel compilation
------------------------

The kernel is compiled using Buildroot's build scripts. The kernel compilation
can be controlled to some degree using Buildroot's Kernel menu. Any patches
applied to the kernel can be found in ``rxos/patches/linux`` directory.

The kernel configuration is found in the ``rxos/configs/rxos_kernel_defconfig``
file.

The following files are generated during the build:

==============  ===============================================================
zImage          kernel image with linked initramfs
--------------  ---------------------------------------------------------------
kernel.img      kernel image with Raspberry-Pi-specific trailer
==============  ===============================================================

The ``kernel.img`` file is created by a post-image hook called
``rxos/scripts/add_trailer.sh``. The script's source includes more information
on what it does and why.

To restart the build from the kernel image compilation you can use the
``rebuild-with-linux`` target.

Rootfs compilation
------------------

The root filesystem image is created from a collection of packages, both from
the Buildroot's own package collection found in ``buildroot/package`` and the
additional Outernet-provided packages found in ``rxos/package``. The
Buildroot's packages are selected using Buildroot's Target packages
configuration section. Outernet-provided packages are selected in various
sections within the User-provided options section of the Buildroot's
configuration menu.

The rootfs format is SquashFS compressed using LZ4 algorithm. This can be
changed in the Buildroot's Target filesystems menu.

To apply small changes to the root filesystem (e.g., a new package was added or
an existing package was updated), run ``make rebuild``. Keep in mind that
Buildroot does not track what files belong to what package. Because of this,
when removing packages, or when updating packages to version that no longer
contain some of the files that they used to contain, you may end up with stray
files from the previous builds. If this happens, ``make rebuild-everything`` or
``make clean build`` should be used instead.

Early userspace
---------------

The early userspace is built last as it is build from pieces of the root
filesystem. The eary userspace image is created in the form of LZ4-compressed
cpio archive by ``rxos/scripts/mkcpio.sh`` script. 

Several compression methods are also supported. This can be changed in the
Filesytem images > initial RAM filesystem section of the Buildroot's
configuration menu. 

Keep in mind, though, that only the methods supported by ``mkcpio.sh`` can be
used, which is currently gzip, XZ, and LZ4.  Also note that kernel needs to
support the compression method used for creating the cpio archive.

Once the cpio archive is genrated, the kernel image is recompiled to include
it.

The contents of the cpio archive are defined by ``rxos/initramfs/init.cpio.in``
template. This template uses several placeholders which look like ``%NAME%``, 
and are populated based on the actual contents of the root filesystem:

==============  ===============================================================
%PREFIX%        Absolute path to the location of the rootfs files
%LIBC_VER%      C library version
%LD_VER%        Linker version
%LD_SFX%        Linker filename suffix (ld-linux-<name>.so)
%INIT%          Path to the init script
==============  ===============================================================

The init script is generated from ``rxos/initramfs/init.in`` template.

Known issues
------------

The build scripts are still under development. In some cases, ``rebuild*``
targets may fail. If a rebuild target fails, try falling back on another one
(e.g., if ``rebuild`` fails, try ``rebuild-with-linux``), and finally do a
``make clean build``.

Also, be sure to report any build issues so we can address them.
