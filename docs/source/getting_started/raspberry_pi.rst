Raspberry Pi
============

In order to build a Raspberry Pi receiver, you will need the following:

- Raspberry Pi 3
- 4GB (or larger) microSD card (8GB and larger is recommended)
- RTL-SDR USB dongle
- LNA
- patch antenna

The RTL-SDR radio dongle, LNA, and antenna, can be purchased `through Outernet
<https://outernet.is/products>`_ either individually or as a kit.

You will also need a Raspberry Pi image, which can be downloaded from
`archive.outernet.is/images/rxOS-Raspberry-Pi
<https://archive.outernet.is/images/rxOS-Raspberry-Pi/>`_.

Flashing the image
-------------------

In order to use this image you will need to flash it to an SD card.

Windows
~~~~~~~

Obtain `Win32 Disk Imager
<https://archive.outernet.is/images/rxOS-Raspberry-Pi/2.0a1-201608151712/>`_.
Open the program (it will ask for administrative privileges), select the image
file and destination drive, and click on "Write".

.. warning::
    Be careful not to select your system drive as the destination drive.

Linux
~~~~~

Insert the card into the card reader. Find out the what your SD card's device
node is by using the ``dmesg | tail`` command. Let's say the device node is
``/dev/sdb1``. 

.. warning::
    Be absolutely sure it's the correct device node. ``dd`` will not ask any
    questions, and will happily overwrite anything you give it. If you are
    unusure, it's best to ask on a Linux forum about how to find out whether
    you have the right device node.

Make sure the SD card is not mounted if you have an
automouter.::

    $ sudo umount -f /dev/sdb1

To write the image to the card::

    $ sudo dd if=sdcard.img of=/dev/sdb1 bs=16m

Mac OSX
~~~~~~~

Insert the card into the card reader. Find out what your SD card's device node
is by using the ``diskutil list`` command. Let's say the device node is
``/dev/disk4``. 

.. warning::
    Be absolutely sure it's the correct device node. ``dd`` will not ask any
    questions, and will happily overwrite anything you give it. If you are
    unusre, it's best to ask on an OSX forum about how to find out whether you
    have the right device node.

You need to unmount the disk::

    $ diskutil unmountDisk /dev/disk4

Finally you can write the image::

    $ dd if=sdcard.img of=/dev/disk4 bs=16m

Connecting the hardware
-----------------------

Once the image is done, put the SD card into the SD card slot. Connect the
antenna to the LNA, and then connect the LNA to the RTL-SDR dongle. Finally,
plug the RTL-SDR dongle into one of the available ports on the Raspberry Pi.

Power the Raspberry Pi on and continue to :doc:`first_steps`.
