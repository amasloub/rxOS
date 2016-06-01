Appendix: Updating rxOS manually
================================

rxOS firmware can be updated manually. There are three ways to update the rxOS
firmware:

- Create a new SD card
- Copy the updated images to the SD card
- Update using shell access

When updating individual files, commonly the following three files are updated:

- ``kernel.img`` - kernel image
- ``root.sqfs`` - root filesystem image (applications)
- ``backup.sqfs`` - a backup copy of the root filesystem image (usually updated
  at the same time the root filesystem image itself is updated)

Here we will discuss the latter two options.

Copy updated images to SD card
------------------------------

The kernel image (``kernel.img``) and the root filesystem image (``root.sqfs``)
can be updated by opening the SD card on a computer and replacing the
matching files on the card.

When replacing ``root.sqfs``, please note that a copy of the file is named
``backup.sqfs``. Ideally we want to replace ``backup.sqfs`` with a copy of
``root.sqfs`` as well.

.. warning::
    Make sure the card is safely removed (unmounted) from the computer. Failing
    to do so may result in partial writes and factory image booting instead of
    the updated one.

Update using shell access
-------------------------

If direct access to the receiver's SD card is impossible, remote shell access
can be used as an alternative method of updating. To update remotely, first use
scp to transfer the files to the receiver. Note that only around 50MB of files
can be stored at a time, so we may need to update files one by one. (For more
information about remote shell access in general, see
:doc:`../how_it_works/remote_access`.)

.. note::
    To check the available space, the following command can be used: ``df -h |
    grep overlay | awk {print $4}``

The boot partition is read-only by default. To make it read-write, we first run
this command::

    $ sudo chbootfsmode
    Password: ********
    Changing /boot to read-write mode.

Next we scp the files to the receiver.

.. note::
    rxOS only supports scp and not sftp, therefore programs like FileZilla
    cannot be used. PuTTY users should use the ``-scp`` option when using
    ``pscp.exe``.

Using PuTTY as an example::

    C:\> pscp -scp root.sqfs outernet@<IP address>:
    outernet@<IP address>'s password: ********
    root.sqfs       | 48548kb | 754.2 kB/s | ETA 00:00:00 | 100%

Now we can copy the file to the boot directory::

    $ sudo mv root.sqfs /boot/
    Password: ********
    mv: can't preserve ownership of '/boot/root.sqfs': Operation not permitted

The error message in the example is harmless and can be ignored.

We repeat the last two steps with any other files we may want to update.
Finally::

    $ sync && sudo reboot

Wait for the receiver to reboot.
