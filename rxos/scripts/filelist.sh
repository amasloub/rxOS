#!/bin/bash
#
# Output a list of files in the rootfs into $BINARIES_DIR/filelist.txt
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

IN="$BINARIES_DIR/rootfs.tar"
OUT="$BINARIES_DIR/filelist.txt"

tar tf "$IN" | sed 's|\./||' > "$OUT"
