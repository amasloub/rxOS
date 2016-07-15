#!/bin/sh
#
# Reattach to the demodulator running inside a sreen session.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
# 
# (c) 2016 Outernet Inc
# Some rights reserved.

SCROLLBACK=6000

while getopts "n" opt; do
  case "$opt" in
    n)
      NONAG=y
      ;;
  esac
done

if [ "$NONAG" != y ]; then
  cat <<EOF
You are about to start the demodulator debug interface.
Use Ctrl+A Ctrl+D combination to detatch from it.

To skip this message next time, start this script as:

  $0 -n

Press any key to continue...
EOF
  read -n1
fi

TERM=vt100 sudo screen -A -h "$SCROLLBACK" -T vt100 -D -r sdr
