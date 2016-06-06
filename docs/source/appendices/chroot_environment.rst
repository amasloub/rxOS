Appendix: Creating a Chrooted Build Environment in Arch Linux
=============================================================

Package requirements:
    - arch-install-scripts
    - devtools

Step 0: Pick a directory
------------------------
Choose the directory you would like to have the chroot's root folder in.
For instance: 

``/home/ben/.chroot/``

Optionally set the variable ``$CHROOT`` to the target directory for copy-paste
later. 

``CHROOT='/home/ben/.chroot/'``

Step 1: Install the base system
-------------------------------
Install the base packages. 

``mkarchroot $CHROOT/root base``

Step 2: Edit the mirror list
----------------------------
Open the mirror list (``$CHROOT/etc/pacman.d/mirrorlist``) with your favorite 
editor, and replace the contents with the line below.

``Server = https://archive.archlinux.org/repos/2016/02/19/$repo/os/$arch``

Step 3: Downgrade the chroot
----------------------------
First log into the chroot with ``sudo arch-chroot $CHROOT /bin/bash``. Then do 
a system downgrade with ``sudo pacman -Syyuu``.

Step 4: Install the requisite packages
--------------------------------------
Use the command below to install packages required for building.

    ``pacman -S base-devel python2 python2-pip bc unzip rsync wget cpio sudo`` 

Step 5: Create a user
--------------------------------------
Use the command below to create a user.

    ``useradd -m -G wheel -s /bin/bash ben``

Leave the chroot logged in and create another session on the host system.
Create a symlink from the user's home directory to somewhere convenient on the
host system, for instance ``ln -s $CHROOT/home/ben/ /home/ben/chroot_home``. 

Step 6: Clone the repo
----------------------
From the host system (so you don't have to install git on the chroot), enter 
the symlinked directory and clone the rxOS repo.

Step 7: Start building!
-----------------------
In the chroot session enter the newly cloned repo under your user's home
directory, then simply run ``make``.
