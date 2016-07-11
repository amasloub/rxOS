#!/bin/sh
#
# Echo network interface information
#
# This file is part of rxOS.
# rxOS is free software licensed under the 
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

. /usr/share/cgi/common.sh

ifconfig
echo
ip addr
echo
ip route
