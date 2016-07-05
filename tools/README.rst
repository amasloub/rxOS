rxOS tools
==========

The ``tools`` directory contains utilities for workign with the rxOS firmware. 


chip-flash.sh
-------------

This script programs the CHIP's NAND flash. It should be invoked in a directory
that contains the build output files (U-Boot binary, kernel image, rootfs
image, etc).

Execute the script with ``-h`` argument to see help information::

    $ tools/chip-flash.sh -h

Given a completed build, you would normally run the script like so::

    $ tools/chip-flash.sh -b out/images

Autoflasher
-----------

The autoflasher consists of:

- ``99-chip-flasher.rules`` udev rules file
- ``autoflash.udev.sh`` udev script
- ``autoflasher.sh`` flashing server
- ``chip-flash.sh`` from the previous section

The flasher udev script and flashing server communicate over a FIFO pipe
created at ``/tmp/autoflasher.fifo``. The udev script will get the bus number
and device number via udev, and relay them to the flashing server via the pipe.
The server will initiate flashing targeting the specific device.

This allows multiple CHIPs to be flashed with rxOS firmware in parallel given a
computer that can prvide enough current to CHIPs through its USB ports, and, of
course, given enough USB ports.

Preparing to flash
~~~~~~~~~~~~~~~~~~

To set up the autoflasher, first edit the ``.rules`` file and adjust the path
to where you copied the ``autoflasher.udev.sh`` script, and copy it to 
``/etc/udev/rules.d/`` directory. Finally, reload the rules::

    $ sudo udevadm control --reload

Prepare the work directory for the autoflasher, and copy ``autoflasher.sh``,
``chip-flash.sh``, and the following files from the build output directory
(``out/images``):

- ``board.ubi``
- ``uboot-dtb.bin``
- ``sunxi-spl.bin``
- ``sunxi-spl-with-ecc.bin``

Start the flashing server by changing the directory to the work directory and
running the ``autoflasher.sh`` as root:

    $ cd /path/to/workdir
    $ sudo ./autoflasher.sh
    Creating FIFO pipe at '/tmp/autoflasher.fifo'
    Creating log directory. Log files are stored in './logs'
    Listening for device IDs...

Prepare all CHIPs by attaching microUSB cables and grounding the FEL pin.

Flashing
~~~~~~~~

To flash the CHIPs, simply plug them into available USB ports. 

The flashing is done when the status LED on the CHIPs start blinking. At that
point, you may remove them from the USB ports.

Troubleshooting
~~~~~~~~~~~~~~~

For each CHIP that is flashed, a log file is generated in ``logs`` diretory
within the work directory. You can look at them to determine if there are any
issues with flashing.
