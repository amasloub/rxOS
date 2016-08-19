What rxOS is and what it isn't
==============================

This section is intended for people who have some familiarity with the `Linux
operating system <https://en.wikipedia.org/wiki/Linux>`_. If you are not
familiar with Linux, you may have some trouble following along, but the
information found in this section is not essential for using an rxOS-based
device so feel free to skip it.

Probably the most important thing to note is that rxOS is not a Linux
distribution. This means that, among other things:

- it has no writable root filesystem
- it has no packages or package manager
- it has no build tools
- it has no system administration tools

Read-only root filesystem
-------------------------

From time to time, we are asked about customizing the rxOS-based receivers.
While some of the configuration persists across reboots, one should not expect
to permanently modify the system outside of the short list of persistent
files.

No packages
-----------

The rxOS image is built as a unit. It is one monolithic system and there is no
notion of packages (nor there ever will be). There are sets of add-on files
that are added on top of the image via the root filesystem overlays (see
:doc:`../building_images/rootfs_overlays` for an in-depth treatment of the
subject), but those are not packages that you install with package managers
such as ``apt`` and ``pacman``.

No build tools
--------------

As mentioned under the previous heading, rxOS is built as a unit. It is built
on a standard Intel PC and then flashed to a device. Because of this there are
no build tools *on* the device. Adding your own programs to the image is done
by rebuilding the image the same way it was originally built (a short guide on
that topic can be found in the :doc:`../building_images/index` chapter).

No sysadmin tools
-----------------

Well, this isn't entirely true. There are some tools for working with the
system. What is missing, though, are things that would normally alter the
system configuration. E.g., there is no support for changing the init script
order and state, there are no system configuration tools, etc. The rxOS system
is mainly intended to be left as is as much as possible, and modification to
the system are done at built time.

What good is all this?
----------------------

While all of this may sound a bit limited, it has some advantages when it comes
to use on embedded devices. 

Writable file systems are susceptible to corruption. If a device is writing
during power loss, the filesystem may be left in a state that makes it
impossible to boot up. 

You can write files to the root filesystem when the system is up and running.
This is done by overlaying a fake filesystem in the system memory (RAM) on top
of the otherwise read-only root filesystem. If there is a bug in the software,
this may sometimes cause the system to exhibit weird behavior. Having a
read-only root filesystem allows the user to power-cycle the device and go back
to the known good state. Not having packages, build tools, and so on, are
design decisions along the same lines: the less modification you can make to
the system, the better the chance of being able to get back to the known good
state.

Another reason rxOS is quite stripped down is that the image needs to be
updated over-the-air (OTA). This puts a restriction on the amount of bandwidth
the image can use, so virtually all non-essential items have been stripped out.
