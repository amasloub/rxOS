rxOS tools
==========

The ``tools`` directory contains utilities for workign with the rxOS firmware. 


chip-flash.sh
-------------

This script programs the CHIP's NAND flash. It should be invoked in a directory
that contains the build output files (U-Boot binary, kernel image, rootfs
image, etc).

Execute the script with ``-h`` argument to see help information::

    $ tools/chip-flash.sh -h

There is a dry run mode which is executed using the ``-D`` argument. In dry
run, everything but the final execution step is run.
