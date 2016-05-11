Source tree layout
==================

- ``buildroot/``: Buildroot submodule
- ``docs/``: Documentation
- ``rxos/``: External board directory
    - ``configs/``: Build configuration
          - ``busybox.config``: Busybox default configuration
          - ``config.txt``: Raspberry Pi bootloader configuration
          - ``rxos_defconfig``: rxOS build defaults
          - ``rxos_kernel_defconfig``: Linux kernel defaults
          - ``users``: User/group list
    - ``installer/``: Files used to create the update package's installer
    - ``local/``: Packages with local source code (mostly system configs)
    - ``package/``: Custom software packages submodule
    - ``patches/``: Custom patches
    - ``rootfs/``: Rootfs overlay
    - ``scripts/``: Build hook scripts
    - ``support/``: Various build hooks
    - ``Config.in``: External board config
    - ``external.mk``: External boad makefile
    - ``local.mk``: Board-specific overrides
- ``Makefile``: Main makefile
- ``README.rst``: README file
