Setting up for remote support
=============================

rxOS allows remote support channel to be set up by adding a simple text file
on an USB stick and plugging it into the receiver.

.. note::
    Because of the security implicatins, remote support channel is only opened
    with full cooperation from Outernet, and only trusted individuals and
    organizations (e.g., partners, clients) will are allowed to use this
    feature.

Configuration file
------------------

The remote access configuration file is named REMOTE (all-caps). The file
contains configuration parameters in ``NAME='value'`` format, exactly one
parameter per line. The following table contains all the possible parameters
and their purpose. All parameters are optional except the ``KEY``.

==========  ======================  ===========================================
Parameter   Example                 Meaning
==========  ======================  ===========================================
PORT        9978                    This value should be a port number issued
                                    by Outernet staff. If omitted, a port
                                    between 20000 and 30000 will be randomly
                                    selected.
----------  ----------------------  -------------------------------------------
HOST        support.outernet.is     Domain name of the support server as
                                    specified by the Outernet staff. If
                                    omitted, hub.outernet.is is used.
----------  ----------------------  -------------------------------------------
NAME        john-lantern            Name of the receiver. This helps the
                                    support staff identify the receiver. If
                                    omitted, the default name 'rxos' is used.
----------  ----------------------  -------------------------------------------
SSID        mywifi                  SSID (access point name) of the access
                                    point which should be used to connect to
                                    Internet. If this is left blank, wireless
                                    connection is not used, and instead, it is
                                    assumed that the receiver will gain access
                                    to Internet by some other means. PASSCODE
                                    parameter is required when using SSID.
----------  ----------------------  -------------------------------------------
PASSCODE    some secret             Passcode (password) of the wireless access
                                    point that should be used to connect to
                                    Internet.
----------  ----------------------  -------------------------------------------
KEY         (gibberish)             Access key that is used to establish a
                                    connection with the server and provided by
                                    the Outernet staff.
==========  ======================  ===========================================

.. warning::
    Any and all values must be quoted using single quotes. Failure to do this
    may result in unexpected behavior.

.. warning::
    NEVER SHARE THE ACCESS KEY WITH ANYONE. You must ensure that the access key
    does not fall into the wrong hands. If the key is misused by a malicious
    user, any receivers connected to the support server or the networks they
    are on may get compromised.

Activating the support connection
---------------------------------

To activate the support connection:

- power down the receiver
- put the ``REMOTE`` file onto USB storage device
- plug the USB storage device into the receiver
- power the reciever up

Deactivating the support connection
-----------------------------------

To deactivate the support connection:

- power down the receiver
- remove the USB storage device from the reciever (if you need to use the
  storage device again, delete the ``REMOTE`` file from it)
- power the receiver up

How it works
------------

When rxOS boots, if the appropriate configuration file and access key are found
on the USB storage device, the networking is reconfigured (when using the
``SSID`` parameter) to access the Internet, and a SSH connection is established
with the remote support server allowing a tunnel from the specified ``PORT``
back to the SSH port on the receiver. The Outernet staff then accesses the
receiver using SSH through this tunnel (reverse SSH).
