#!/bin/sh

if grep -q BOARD=dc /proc/cmdline
then
    exec /init.dc
else
    exec /init.chip
fi
