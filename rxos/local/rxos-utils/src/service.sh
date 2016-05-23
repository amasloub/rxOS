#!/bin/sh
#
# Simple wrapper that makes it easy to invoke init scripts without knowing the
# order number.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

name="$1"
action="$2"

usage() {
    echo "Usage: $0 SERVICE ACTION"
    echo 
    echo "   SERVICE - name of the init script without the SNN prefix"
    echo "   ACTION  - start, stop, or restart"
    echo 
}

if [ -z "$name" ] || [ -z "$action" ]
then
    usage
    exit 1
fi

sudo /etc/init.d/S??"$name" "$action"
