#!/bin/sh
#
# Prepare any uninitialized ubi volumes for mounting.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
# 
# (c) 2016 Outernet Inc
# Some rights reserved.

# Parameters
CONF_SIZE="%CONF%"      # configuration partition size
CACHE_SIZE="%CACHE%"    # cache partition size
DATA_SIZE="%APPDATA%"   # application data partition size

ERRORS=

hasubivol() {
  name="$1"
  ubinfo -d 0 -N "$name" 1> /dev/null 2>&1
}

mkubi() {
  name="$1"
  size="$2"
  hasubivol "$name" && return 0
  if [ "$size" = MAX ]; then
    ubimkvol -N "$name" -m
  else
    ubimkvol -N "$name" -s "${size}MiB"
  fi
}

warn() {
  msg="$*"
  echo "WARNING: $msg"
  ERRORS=y
}

mkubi "conf" "$CONF_SIZE" || warn "Could not create 'conf' volume"
mkubi "cache" "$CACHE_SIZE" || warn "Could not create 'cache' volume"
mkubi "appdata" "$DATA_SIZE" || warn "Could not create 'appdata' volume"
mkubi "data" MAX || warn "Could not create 'data' volume"

if [ "$ERRORS" = "y" ]; then
  exit 1
else
  exit 0
fi
