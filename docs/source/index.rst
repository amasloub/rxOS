****
rxOS
****

rxOS is a Linux-based operating system (and also the system image) that is used
in Outernet's Lantern and Lighthosue Mk 2 products, both based on Raspberry Pi
3.

rxOS is built on top of `Buildroot <http://buildroot.org/>` and constists of
two parts:

- Linux kernel image with early userspace
- rootfs image

Documentation
=============

.. toctree::
    :maxdepth: 1

    requirements
    build
    source_tree_layout
    make_targets
    boot
    storage_layout
    ota_updates
