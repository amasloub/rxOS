Make targets
============

The following table describes the available make targets:[1]_

=================   ===========================================================
target              function
=================   ===========================================================
version             Get current version
-----------------   -----------------------------------------------------------
build [2]_          Build both SD card image and update package
-----------------   -----------------------------------------------------------
menuconfig          Bring up Buildroot configuration menu
-----------------   -----------------------------------------------------------
linuxconfig         Bring up Linux kernel configuration menu
-----------------   -----------------------------------------------------------
busyboxconfig       Bring up Busybox configuration menu
-----------------   -----------------------------------------------------------
saveconfig          Save all configuration
-----------------   -----------------------------------------------------------
config              Load default configuration (overwrites any modifications)
-----------------   -----------------------------------------------------------
rebuild             Perform partial cleanup and rebuild
-----------------   -----------------------------------------------------------
clean-build         Partial cleanup (useful when trying to apply small
                    modifications)
-----------------   -----------------------------------------------------------
clean               Complete cleanup (also removes any unsaved modifications)
=================   ===========================================================

.. [1] Targets described here are custom targets for rxOS build. Full set of
       Buildroot's own ``make`` targets are also available.
.. [2] Default target when invoking ``make``
