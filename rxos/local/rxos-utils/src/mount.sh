#!/bin/sh
#
# Echo mounts
#
# This file is part of rxOS.
# rxOS is free software licensed under the 
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

. /usr/share/cgi/common.sh

cat /proc/mounts
echo
df -h
