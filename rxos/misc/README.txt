=================
Flashing the CHIP
=================

This file describes the process of setting up your Linux machine for flashing
CHIP.

Source license
**************

This software is provided as is without any warranties.

rxOS is free software licensed under the GNU GPL version 3 or any later
version. You can obtain the source code of the build here:

    https://github.com/Outernet-Project/rxOS/

(c)2016 Outernet Inc
Some right reserved.

Serial console
**************

It helps to have access to a serial console. You will need an UART-USB or
similar adapter. The UART pins are located on the U14 pin header on the
inside, near the microUSB connector, marked as UART-TX and UART-RX. If the
board is powered from a source other than the PC to which the UART is
connected, remember to also plug in the ground lead to one of the pins marked
as GND on the CHIP (one is conveniently provided right next to the UART pins).

Preparing the system
********************

NOTE: The instructions pointed to by the following paragraph will contain a
section on udev rules. They may not work, so feel free to skip it. An
alternative method is provided in this document.

Please follow the instructions on this page[1] and return to this file once you
finish the "Set up Ubuntu for flashing" *section* that is pointed to by the 
link.

[1] http://docs.getchip.com/chip.html#setup-ubuntu-for-flashing

For convenience the udev rule mentioned in the documentation is provided as a
file (99-chip.rules). If you wish to skip the udev step in the documentation,
you can use the provided .rules file: 

- First edit the file and replace any references to 'plugdev' with your 
  username (more precisely, a group which matches your username, or any other 
  group that your user already belongs to, like 'users')
- Then copy the file to /etc/udev/rules.d/
- Reload the udev rules with this command:

    sudo udevadm control --reload-rules

In the cloned CHIP-tools repository, you need to build the spl-image-builder
binary:

    $ cd CHIP-tools
    $ make

The binary has to be on PATH. You can copy it to /usr/local/bin, or some other
path that is already on PATH (run `echo $PATH` on the command line to see which
directories are on PATH), or you can temporarily override the PATH by running
commands like so:

    $ PATH=$PATH:/path/to/CHIP-tools <command>

Flashing
********

CHIP must be put into FEL mode before it can be flashed. To do this you will
need a (relatively thin) paper clip, or a twist tie with stripped ends (exposed
wire). With the paper clip or twist tie, connect the pins marked as FEL and
GND. The FEL pin is located at the 4th position in the inside row towards the
microUSB port. GND pin is located at the last position in the same row as the
FEL pin. Once the pins are connected, plug the CHIP into a USB port.

You should see a device node /dev/usb-chip. If you don't see it, your udev
rules may need a refresh, or you may need to check the rules file for typos.

Now open a terminal and navigate to where you unpacked the flash files. Start
the flash script:

    bash chip-flash.sh

Example output may look like this:

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
