Remote shell access
===================

rxOS only supports the following methods for remotely accessing the system::

- SSH over wireless hotspot (Pi3 and CHIP)
- SSH over Ethernet (Pi3)
- SSH over USB Ethernet (CHIP)
- Serial console over USB (CHIP)
- Serial console over UART (CHIP)

IP addresses
------------

The following addresses are assigned to on-board network interfaces:

==============  ===============
interface       address
==============  ===============
WiFi            10.0.0.1
USB Ethernet    10.10.10.10
Ethernet        dynamic (DHCP)
==============  ===============

Connecting to networks
----------------------

rxOS-based receivers have several ways to network with other devices and
networks.

Wireless hotspot
~~~~~~~~~~~~~~~~

When a receiver is started, a wireless network is created automatically. The
default network name (SSID) is "Outernet" and is not password-protected.

USB Ethernet (CHIP only)
~~~~~~~~~~~~~~~~~~~~~~~~

USB Ethernet connection is establish when the receiver is plugged in to a
computer using the microUSB cable. Assignment of IP address to the connected
computer is automatic.

Ethernet connection (Raspberry Pi3 only)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The receiver can be connected to a router, and it will automatically obtain an
IP address. Since this IP address is dynamic, you will need to consult your
router's administrative interface, or use the wireless hotspot on the receiver
to find the IP address that was assigned.

SSH access
----------

For SSH access, use port 22 and username ``outernet``. The default password for
the ``outernet`` user is ``outernet``.

.. note::
    Once you go through the setup wizard in the web inteface, the SSH user will
    change to the superuser credentials that you set up during the wizard.
    Please adjust accordingly.

Root login is not enabled, but ``sudo`` can be used to gain full root access::

    [rxOS][outernet@rxos ~]$ sudo su
    Password: ********
    [rxOS][root@rxos /home/outernet]# _


USB serial console access (CHIP only)
-------------------------------------

USB serial console becomes available when the receiver is connected to a
computer using a microUSB cable. Software such as PuTTY, screen, or minicom,
can be used to access this console. This console is log-in only and does not
show boot messages. For a more comprehensive console access, UART console is
recommended.

UART console (CHIP only)
------------------------

USB-UART adapter (not included) can be plugged into the UART pin headers on the
CHIP to provide access to UART console. Depending on the receiver design, the
case may need to be removed to gain access the these pins. Software such as
PuTTY, screen, or minicom, can be used to access this console.

The UART console provides access to boot messages, and allows the user to
interact with not just rxOS, but also the U-Boot bootloader.

Changing the user password
--------------------------

User password can be changed using the ``passwd`` command::

    [rxOS][outernet@rxos ~]$ passwd
    Current password: *******
    Enter new password: ******
    Retype new password: ******
