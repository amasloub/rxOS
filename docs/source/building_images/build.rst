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

Before you build
----------------

Before you build, you need to clone the rxOS git repository::

    $ git clone --recursive https://github.com/Outernet-Project/rxOS.git

The ``--recursive`` flag causes git to init and update any submodules. If you
forgot it, you need two additional steps::

    $ git submodule init
    $ git submodule update

Starting the build
------------------

The build is initated by invoking ``make`` or ``make build``.

To completely clean up the build and restart it from scratch, use ``make clean
build``. It is generally not needed to do this, though. In most cases, a more
efficient alternative is to call ``make rebuild-everything``.

Customizing the build
---------------------

To customize the build use ``make menuconfig``, which brings up the Buildroot's
configuration menu.

Updating the existing build
---------------------------

To update your local repository clone::

    $ cd path/to/rxOS
    $ git pull
    $ git submodule update

Apply possibly updated build configuration::

    $ make config

Rebuild starting from the linux kernel::

    $ make rebuild-with-linux

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
files from the previous builds. If this happens, ``make clean build`` should be 
used instead.

Early userspace
---------------

The early userspace is built last as it is built from pieces of the root
filesystem. This is facilitated by the Outernet-specific patches applied to the
version of Buildroot used by rxOS. 

The initial RAM disk (initramfs) image is build as a compressed cpio archive,
and the list of files that end up in the final initramfs image is controlled by
several different packages, including the ``ramfsinit`` local package. The
packages each provide a template that points the kernel's ``gen_init_cpio``
script to appropriate files in the root filesystem.

Known issues
------------

The build scripts are still under development. In some cases, ``rebuild*``
targets may fail. If a rebuild target fails, try falling back on another one
(e.g., if ``rebuild`` fails, try ``rebuild-with-linux``), and finally do a
``make clean build``.

Also, be sure to report any build issues so we can address them.
