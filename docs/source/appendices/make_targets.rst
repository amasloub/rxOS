Appendix: Make targets
======================

The following table describes the available make targets:[1]_

======================  =======================================================
target                  function
======================  =======================================================
version                 Get current version
----------------------  -------------------------------------------------------
build [2]_              Build both SD card image and update package
----------------------  -------------------------------------------------------
menuconfig              Bring up Buildroot configuration menu
----------------------  -------------------------------------------------------
linuxconfig             Bring up Linux kernel configuration menu
----------------------  -------------------------------------------------------
busyboxconfig           Bring up Busybox configuration menu
----------------------  -------------------------------------------------------
saveconfig              Save all configuration
----------------------  -------------------------------------------------------
config                  Load default configuration (overwrites any 
                        modifications)
----------------------  -------------------------------------------------------
rebuild                 Rebuild the rootfs and recompile linux with initramfs
----------------------  -------------------------------------------------------
rebuild-with-linux      Completely rebuild the linux kernel, DTB, and rootfs
----------------------  -------------------------------------------------------
rebuild-everything      Rebuild everything except host tools/libs
----------------------  -------------------------------------------------------
clean-rootfs            Partial cleanup (useful when trying to apply small
                        modifications)
----------------------  -------------------------------------------------------
clean-linux             Partial cleanup (useful when linux configuration 
                        changes)
----------------------  -------------------------------------------------------
clean-deep              Clean everything except host tools/libs
----------------------  -------------------------------------------------------
clean                   Complete cleanup (also removes any unsaved 
                        modifications)
----------------------  -------------------------------------------------------
print-post-script-args  Print the arguments that would be passed to the 
                        post-build and post-image hooks.
----------------------  -------------------------------------------------------
manual                  Build the HTML manual and output it to
                        ``docs/build/html``.
======================  =======================================================

.. [1] Targets described here are custom targets for rxOS build. Full set of
       Buildroot's own ``make`` targets are also available.
.. [2] Default target when invoking ``make``
