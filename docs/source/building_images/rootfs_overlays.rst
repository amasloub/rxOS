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
    $ mksquashfs overlay/ overlay-hello-1.0.sqfs -comp lz4 -Xhc

The output file name must be named ``overlay-<name>-<version>.sqfs`` because
that is the pattern that the init script looks for. The ``name`` should not
contain any dashes or spaces. The ``version`` can be in the X.Y or X.Y.Z format
and the following suffixes are supported:

- aN - alpha version N
- bN - beta version N
- rcN - release candidate N

Here are some examples of valid version numbers:

- 1.0a2 - second alpha version for 1.0 release
- 2.0b1 - first beta version for 2.0 release
- 3.1 - third major, fist minor release
- 1.3.002 - first major, third minor, second patch release
- 5.1rc2 - second release candidate for 5.1 release

Booting with an overlay
-----------------------

To create an image that includes overlays, put them in
``out/images/sdcard-extras`` directory for SD card builds (e.g., Raspberry Pi), 
and ``out/imags/overlays`` for NAND builds (e.g., CHIP).

To install an overlay to a running system, upload the overlay to the receiver,
and then::

    $ sudo chbootfsmode
    $ sudo mv <path/to/overlay> /boot
    $ sudo chbootfsmode
    $ sudo reboot

Creating update packages for overlays
-------------------------------------

The ``tools`` directory contains a script called ``mkoverlaypkg.sh``. This
script will create an OTA update ``.pkg`` file for any overlay images found in
``out/images/overlays``. Run the script with ``-h`` flag to see the options it
supports.

The generated overlay files have the following naming convention::

    rxos-<platform version>-overlay-<name>-<version>-<timestamp><suffix>.pkg

- ``platform version`` can be a version of a rxOS release (e.g., v1.0) or
  ``any``. If the version is specified, the update package can only be
  installed on that particular version of rxOS.
- ``name`` is the overlay name, and only overlays that have the same name that
  are *already installed* are going to be updated by the generated upate
  package
- ``version`` is the overlay version, and if version check is enabled (see
  ``suffix`` below), only overlays that are newer than the already installed
  overlay are upgraded
- ``timestamp`` is a timestamp in local time, when overlay package was created
- ``suffix`` can be either a blank string or ``nv``, for non-version-checking
  package
