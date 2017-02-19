rxOS
====

rxOS is the operating system and firmware image for the second generation
Outernet receivers (Lantern and Lighthouse Mk 2).

rxOS is built on top of `Buildroot <http://buildroot.org/>` and constists of
two parts:

- Linux kernel image with early userspace
- rootfs image

Full documentation is available in the ``docs`` subdirectory.

The code is released under GPLv3 license. See the ``COPYING`` file in the
source tree or visit `<http://www.gnu.org/licenses/>`_.

Required software
-----------------

In order to build the rxOS firmware, you will need a Linux (virtual) machine. 

For virtual machines, hardware virtualization (Hyper-V, etc) is highly
recommended, as well as as much RAM as you can spare.

You will need to have the following packages installed:

- Build tools (packages like build-essential, base-devel, and similar)
- bc
- git
- rsync
- unzip
- cpio
- wget
- mercurial (hg)

Quick start
-----------

Before you start, you need to clone the rxOS git repository::

    $ git clone --recursive https://github.com/Outernet-Project/rxOS.git -b develop

The ``--recursive`` flag causes git to init and update any submodules. If you
forgot it, you need two additional steps::

    $ git submodule init
    $ git submodule update

Now you can ``cd`` into the repository and start building::

    $ cd rxOS
    $ make menuconfig  # only if you want to customize something
    $ ./skylark-chip

If the build stops with a "thbbt!", comment out the "exit 1" line
near the top of the script in build.sh, unless you are building for 
release, in which case take the error message seriously and fix the 
problem.

Updating the existing build
---------------------------

To update your local repository clone::

    $ cd path/to/rxOS
    $ git pull
    $ git submodule update

Apply possibly updated build configuration::

    $ make config

Rebuild starting from the linux kernel::

    $ ./skylark-chip clean && ./skylark-chip

User makefiles
--------------

Any makefiles in the root of the source directory that are named ``user*.mk``
will be included in the build, after all local and build packages, and support
makefiles are executed. This makefiles can be used for temporary overrides and
slight build adjustments.

**Do not abuse user makefiles!** The more personal you make the build, the
smaller the chance someone will be able to help you with it. 

Example user makefiles are provided in the ``user`` directory. These makefiles
are actually used in production so consider them 'working examples'. They can
be symlinked to the source root.

License
-------

rxOS is free software: you can redistribute it and/or modify it under the terms
of the GNU General Public License as published by the Free Software Foundation,
either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. See ``COPYING`` file in the source tree. If not, see
`<http://www.gnu.org/licenses/>`_.
