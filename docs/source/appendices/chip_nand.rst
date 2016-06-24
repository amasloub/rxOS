Appendix: C.H.I.P. NAND storage characteristics
===============================================

C.H.I.P. has built-in NAND flash storage mounted on the top side of the board.
It's an 8GB SK-hynix-branded SLC NAND chip.

NAND characteristics
--------------------

The following table contains information returned by executing ``nand info`` in
the U-Boot shell.

==================  ======================  ===================================
Capacity            8589934592 B (8 GiB)    0x200000000
Erase block size    4194304 B (4 MiB)       0x400000
Page size           16384 B (16 KiB)        0x4000
Subpage size        16384 B (16 KiB)        0x4000
OOB                 1664 B                  0x680
Options                                     0x40003200
BBT Options                                 0x00110000
==================  ======================  ===================================

Information returned by ``mtdinfo`` is as follows::

    Type:                           mlc-nand
    Eraseblock size:                4194304 bytes, 4.0 MiB
    Amount of eraseblocks:          2044 (8573157376 bytes, 8.0 GiB)
    Minimum input/output unit size: 16384 bytes
    Sub-page size:                  16384 bytes
    OOB size:                       1664 bytes
    Character device major/minor:   90:8
    Bad blocks are allowed:         true
    Device is writable:             true
    Default UBI VID header offset:  16384
    Default UBI data offset:        32768
    Default UBI LEB size:           4161536 bytes, 4.0 MiB
    Maximum UBI volumes count:      128

Additional notes
----------------

Normally about a dozen or more bad sections will be found on first boot.
