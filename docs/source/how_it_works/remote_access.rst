Remote shell access
===================

rxOS only supports SSH for remote shell access.

IP addresses
------------

The following addresses are assigned to on-board network interfaces:

==========  ===============
interface   address
----------  ---------------
Ethernet    dynamic (DHCP)
WiFi        10.0.0.1
==========  ===============

SSH access
----------

For SSH access, use port 22 and username ``outernet``. The default password for
the ``outernet`` user is ``outernet``.

Root login is not enabled, but ``sudo`` can be used to gain full root access::

    $ sudo su
    [sudo] password for outernet: ********
    #
