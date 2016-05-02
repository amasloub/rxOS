About the patches
=================

The rxos/patches directory contains patches for the software that is built into
the firmware. These patches usually come from 3rd parties. This file documents
the patches that are present in this drectory and lists their sources and
licenses.

==============  =====  =======================  =======  ======================
package         patch  source                   license  purpose
==============  =====  =======================  =======  ======================
hostapd/2.5     0000   http://bit.ly/1SAQvU8    GPL      enables support for 
                                                         AP mode capable
                                                         Realtek WiFi devices.
--------------  -----  -----------------------  -------  ----------------------
hostapd/2.5     0001   n/a                      n/a      enable the
                                                         configuration option
                                                         for Realtek driver
                                                         so that the driver
                                                         is built
--------------  -----  -----------------------  -------  ----------------------
linux           0000   Outernet                 GPL      modified boot-up logo
==============  =====  =======================  =======  ======================

.. note::
    Where source and/or license columns say 'n/a', the file's source and
    license information are unaccounted for and/or not documented in the file
    itself. Please do not assume any source or license. Outernet patches have
    'Outernet' under the source column, and are always under GPL license unless
    that conflicts with the software being patched.
