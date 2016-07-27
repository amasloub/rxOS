#!/bin/sh
#
# Create or clear the tempdir
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

TMPDIR="%TMPDIR%"

[ -d "$TMPDIR" ] && rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"
