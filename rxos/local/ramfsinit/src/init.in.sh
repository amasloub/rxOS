#!/bin/sh

if [ -e /dev/mmcblk0p1 ]
then
    exec /init.dc
else
    exec /init.chip
fi
