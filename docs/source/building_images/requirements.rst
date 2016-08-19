Build requirements
==================

In order to build the rxOS firmware, you will need a Linux (virtual) machine. 

For virtual machines, hardware virtualization (Hyper-V, etc) is highly
recommended, as well as as much RAM as you can spare.

You will need to have the following packages installed:

- Build tools [1]_
- bc
- git
- rsync
- unzip
- cpio
- wget
- mercurial (hg)

.. note::
    Here are some commands for installing build tools on different distros:

    Ubuntu/Debian and derivatives::

        $ sudo apt-get install build-essential

    Fedora::

        $ sudo yum groupinstall "Development Tools" "Development Libraries"

    Arch Linux::

        $ sudo pacman -Sy base-devel

    Opensuse::

        $ sudo zypper install --type pattern devel_basis


.. [1] The build tools include compilers (e.g., gcc), standard libraries, and 
       build automation tools (make, automake, autoconf, etc). In some Linux
       distributions, there are packages that bundle these tools together
       (e.g., 'build-essential' on Ubuntu, or 'base-devel' on Arch Linux). If
       you are unsure, try googling "build-essential equivalent for <distro
       name>".
