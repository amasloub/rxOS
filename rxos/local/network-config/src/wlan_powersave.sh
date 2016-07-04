#!/bin/sh
#
# Disable power-saving on wlan0
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

/usr/sbin/iw dev "$INTERFACE" set power_save off
