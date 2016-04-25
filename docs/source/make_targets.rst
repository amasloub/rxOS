Make targets
============

The following table describes the available make targets:

=================   ===========================================================
target              function
=================   ===========================================================
version             Get current version
-----------------   -----------------------------------------------------------
build [1]_          Build both SD card image and update package
-----------------   -----------------------------------------------------------
flash               Build the SD card image only
-----------------   -----------------------------------------------------------
update              Build the update package only
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

.. [1] Default target when invoking ``make``
