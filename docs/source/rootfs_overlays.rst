Root filesystem overlays
========================

rxOS supports customizing the base image using root filesystem overlays
(henceforth we'll refer to them simply as just 'overlays'). Overlays are
SquashFS images that contain a set of files and directories that either augment
or override the base root filesystem contents.

The benefit of using overlays as opposed to modified root filesystem images
are:

- ability to receive OTA updates meant for the base root filesystem only while
  retaining the customization intact
- simpler build process as the full build environment is not needed for most
  simple overlays
- OTA update for the overlay itself does not consume too much bandwidth as
  overlays are typically small

There is no limit to the number of overlays that can be added to the system,
though one should be mindful about RAM usage as each overlay is loop-mounted.

Creating an overlay image
-------------------------

To create an overlay image, we first prepare a directory with the image
contents, and then convert it using squashfs-tools. Only LZ4-compressed images
are supported at the moment.

As an example, we will prepare an overlay that contains a single text file.

First prepare the work directory::

    $ mkdir overlay && cd overlay

Next we create the directory where we will keep our text file and the text file
itself::

    $ mkdir -p opt/doc
    $ echo 'Hello world!' >> opt/doc/hello.txt

Finally, we adjust the ownership of the directories::

    $ sudo chown -R 0:0 opt/doc

.. note::
    We are using numeric IDs for the user and group. Since user and group names
    on your system may not map to the same IDs on rxOS, you should stick to
    using 0 for root, and 1000 for the outernet user.

We are now ready to create the SquashFS image::

    $ cd ..  # Exit overlay directory
    $ mksquashfs overlay/ overlay-hello.sqfs -comp lz4 -Xhc

The output file name must be named ``overlay-<name>.sqfs`` because that is the
pattern that the init script looks for.

Booting with an overlay
-----------------------

To boot with an overlay, simply put the overlay file on the SD card, and boot.

To add the overlay to the build-generated SD card image, put it in
``out/images/sdcard-extras``.
