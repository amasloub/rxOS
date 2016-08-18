C.H.I.P
=======

In order to build a CHIP-based receiver, you will need the following:

- CHIP
- RTL-SDR USB dongle
- LNA
- patch antenna
- microUSB cable with data connection
- (optional) USB hub, if you wish to connect both the RTL-SDR dongle and some
  other device, like USB storage
- (optional) UARD USB adapter, if you wish to monitor the boot loader output
- (optional) USB Ethernet adapter for wired network connection

You will also need a CHIP image, which can be downloaded from
`archive.outernet.is/images/rxOS-Raspberry-Pi
<https://archive.outernet.is/images/CHIP/>`_.

Flashing the image
-------------------

At this time, CHIP can only be flashed from a Linux machine, either a virtual
machine or a native install.

Serial console
~~~~~~~~~~~~~~

It helps to have access to a serial console. You will need an UART-USB or
similar adapter. The UART pins are located on the U14 pin header on the
inside, near the microUSB connector, marked as UART-TX and UART-RX. If the
board is powered from a source other than the PC to which the UART is
connected, remember to also plug in the ground lead to one of the pins marked
as GND on the CHIP (one is conveniently provided right next to the UART pins).

Preparing the system
~~~~~~~~~~~~~~~~~~~~

To access CHIP as a normal user, you will need to set up the udev rules so that
the device has appropriate permissions when plugged in. Download the
:download:`99-chip.rules <../files/99-chip.rules>` file. Edit the file with
your favorite editor, and change all referneces to ``plugdev`` to your
username. Alternatively, you can add your user to the ``plugdev`` group.

Reload the udev rules with this command::

    $ sudo udevadm control --reload-rules

Next we need to set up the software. Using your systme's package manager,
install the following software (possible package names are specified in
parenthesis):

- build tools (see note below)
- git (git)
- dd (coreutils)
- lsusb (usbutils)
- fel (sunxi-tools)
- mkimage (uboot-tools)
- fastboot (android-tools or android-tools-fastboot)
- img2simg (android-tools, simg2img, or android-tools-fsutils)

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

We will need to clone a few Git repositories which contain non-standard tools
that are not commonly available as packages (yet)::

    $ git clone https://github.com/NextThingCo/CHIP-tools.git
    $ git clone https://github.com/linux-sunxi/sunxi-tools.git

We need to compile these tools so run a few more commands::

    $ cd CHIP-tools
    $ make
    $ CHIP_TOOLS=$(pwd)
    $ cd ../sunxi-tools
    $ make
    $ FEL=$(pwd)

Don't close the terminal just yet.

Flashing
~~~~~~~~

CHIP must be put into FEL mode before it can be flashed. To do this you will
need a (relatively thin) paper clip, or a twist tie with stripped ends (exposed
wire). With the paper clip or twist tie, connect the pins marked as FEL and
GND. The FEL pin is located at the 4th position in the inside row towards the
microUSB port. GND pin is located at the last position in the same row as the
FEL pin. Once the pins are connected, plug the CHIP into a USB port.

You should see a device node /dev/usb-chip. If you don't see it, your udev
rules may need a refresh, or you may need to check the rules file for typos.

In the terminal where you set the software up, navigate to where you unpacked
the flash files. Start the flash script:

.. code-block:: text

    $ cd path/to/firmware/directory
    $ PATH="$PATH:$CHIP_TOOLS:$FEL" bash chip-flash.sh
    [  0.01 ] ===> Preparing the payloads
    [  0.01 ] .... Preparing the SPL binary
    [  0.01 ] .... Preparing the U-Boot binary
    [  0.30 ] .... Preparing sparse UBI image
    [  0.41 ] ===> Creating U-Boot script
    [  0.42 ] .... Writing script source
    [  0.42 ] .... Writing script image
    [  0.42 ] ===> Uploading payloads
    [  0.43 ] .... Waiting for CHIP in FEL mode...OK
    [  0.44 ] .... Executing SPL
    [  1.97 ] .... Uploading SPL
    [  8.86 ] .... Uploading U-Boot
    [ 16.15 ] .... Uploading U-Boot script
    [ 16.16 ] ===> Executing flash
    [ 16.17 ] .... Waiting for fastboot.......OK
    target reported max download size of 314572800 bytes
    sending 'UBI' (204800 KB)...
    OKAY [ 16.949s ]
    writing 'UBI'...
    OKAY [ 44.200s ]
    finished. total time: 61.149s
    resuming boot...
    OKAY [  0.000s ]
    finished. total time: 0.000s
    [101.84] ===> Cleaning up
    [101.86] ===> Done

    !!! DO NOT DISCONNECT JUST YET. !!!

    Your CHIP is now flashed. It will now boot and prepare the system.
    Status LED will start blinking when it's ready.

As the message says, within about 2 minutes, the status LED will start
blinking. At that point, you will be able to start using your newly flashed
CHIP.

Note on fastboot and virtual machines
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you are using a virtualmachine (e.g., VirtualBox or VMware), you should be
aware that, during the flashing, when the "Waiting for fastboot" message
appears, the CHIP will change its USB ID. This means that the USB ID you
originally set up while it was in FEL mode will no longer apply, and the
guest OS will loose the connection to CHIP. This results in fastboot timeout.

Once fastboot times out, you should reconfigure your virtual machine manager to
make the new USB ID available to the guest.

Connecting the hardware
-----------------------

Connect the antenna to the LNA, and then connect the LNA to the RTL-SDR dongle.
Finally, plug the RTL-SDR dongle into the USB port on the CHIP.

Power the CHIP on and continue to :doc:`first_steps`.
