#!/bin/sh
#
# If FSAL socket is found, it will send a command over IPC to it that will
# trigger an index refresh.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

FSAL_SOCKET="/var/run/fsal.ctrl"

# Noop if fsal is not available
[ -f $FSAL_SOCKET ] || exit 0

# Request FSAL index refresh
printf '<request><command><type>refresh</type></command></request>\0' \
  | nc "local:$FSAL_SOCKET"
