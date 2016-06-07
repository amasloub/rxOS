Appendix: Creating a chrooted build environment under Arch Linux
================================================================

Because the rxOS build depends on a large number of complex software packages,
and Arch Linux is a rolling release distribution, discrepancies between the
package versions installed on developers' machines may lead to random build
failure for some. To ensure maximum compatibility, we can set up a build
environment in a chroot and fix the package versions to known good ones.

A chroot is more or less a full Linux distro within a distro (sans the kernel,
init scripts, bootloader, and things you do not need for bootstrapping). It is
created in an arbitrary directory within our install, and can use different
versions of software as if they were installed on the host system.

Arch Linux makes it easy to create the chrooted environment by making the
scripts normally used during installation available in form of packages.

Requirements
------------

To build the chrooted environment, you will need a working Arch Linux install,
and the following packages:

- ``arch-install-scripts``
- ``devtools``

Creating the chroot
-------------------

We will first pick a directory where we will keep our chroot(s). Let's call
this directory ``chroots`` for simplicity::

    $ mkdir chroots

Once we have the directory, we create the actual chroot directory within it::

    $ mkarchroot chroots/buildroot base

The ``base`` argument is the name of the package group we want installed in the
chroot. Although we can install any number of packages, we won't do it at this
stage because we want to downgrade all installed packages to a known good
version. At this step, we merely want to install packages that will allow us to
do so later.

Next we need to edit the ``mirrorlist`` file *within the chroot* to facilitate
the downgrade. ::

    $ echo 'Server = https://archive.archlinux.org/repos/2016/02/19/$repo/os/$arch' \
        > chroots/buildroot/etc/pacmand.d/mirrorlist

Once the mirrorlist is edited, we can enter the chroot, remove unnecessary
packages and downgrade the packages we need::

    $ sudo arch-chroot chroots/buildroot /bin/bash
    # pacman -Rncs linux linux-firmware systemd
    # pacman -Syyuu

.. note::
    If you use a terminal emulator that isn't quite xterm-compatible, you may
    need to install terminfo files for your terminal emulator within the
    chroot. For urxvt, for example, you need to install
    ``rxvt-unicode-terminfo`` package. Neglecting to do so will result in weird
    terminal behavior such a Backspace not echoing correctly.

Next we install the build prerequisites::

    # pacman -S base-devel python2 git mercurial bc unzip rsync wget cpio

Once everything is installed, we can remove the package cache to recover disk
space::

    # pacman -Scc

Creating the unprivileged user
------------------------------

There is no need, nor it is desirable, to perform the builds as root.
Therefore, we need a normal user account to use while building. Inside the
chroot we run the following command::

    $ useradd -Umk /etc/skel <USERNAME>

Making development files available to the chroot
------------------------------------------------

While inside the chrooted environment, we cannot access any files on the host
system. Since it is wasteful to clone the code inside the chroot, install all
the development tools, and otherwise bloat the chroot, we will make the
development files (local git repository) available within the chroot. This
allows us to user our normal environment to work on the files (edit, etc),
while using the chroot for the actual build.

Since symlinking to location outside the chroot does not work, we will use a 
bind mount instead. From the host system::

    $ sudo mount --bind /path/to/local/repo \
        chroots/buildroot/home/<USERNAME>/rxos

Building
--------

Now whenever we want to build, we enter the chroot and build as the
unprivileged user::

    $ sudo arch-chroot chroots/buildroot /bin/bash
    # su <USERNAME>
    $ cd rxos
    ... build commands ...
