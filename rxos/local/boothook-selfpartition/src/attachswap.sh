#!/bin/sh

# nand storage
if [ -e /dev/mtdblock4 ]
then
    mkswap /dev/mtdblock4
    swapon /dev/mtdblock4
fi

# sdcard storage
if [ -e /dev/mmcblk0p2 ]
then
    mkswap /dev/mmcblk0p2
    swapon /dev/mmcblk0p2
fi
