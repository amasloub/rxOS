#!/bin/sh

PATH=/bin

CONSOLE=/dev/console

# Set the date to a sane value
date -u "2017-01-01 0:00:00"

# Populate the /dev, /proc, and /sys directories
mkdir -p /sys /proc /dev
mount -t devtmpfs devtmpfs /dev
mount -t proc proc /proc
mount -t sysfs sysfs /sys

# Setup console
exec 0<$CONSOLE
exec 1>$CONSOLE
exec 2>$CONSOLE


if  grep -q BOARD=dc /proc/cmdline
then
    exec /init.dc
else
    exec /init.chip
fi
