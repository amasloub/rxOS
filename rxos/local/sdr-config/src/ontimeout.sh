#!/bin/sh
#
# Reset the sdr service and prevent multiple attempts to reset to run at the
# same time by using a lock file.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

LOCK_FILE="/var/run/ontimeout.lock"
PATH="${PATH}:/usr/bin:/usr/sbin:/bin:/sbin"
export PATH

# Don't do anything when there's a lock file
[ -f "$LOCK_FILE" ] && exit 0

touch "$LOCK_FILE"  # Lock to prevent other instances from running
service sdr reset
rm -f "$LOCK_FILE"
