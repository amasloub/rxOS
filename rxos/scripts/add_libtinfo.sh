#!/bin/bash
#
# Add libtinfo.so* symlink pointing at libncursesw.so*. 
#
# The demod binary is linked against libtinfo which appears to be the same
# thing as libncursesw, based on libtinfo package in AUR[1].
#
# This script should be run as a post-build hook.
#
# [1] https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=libtinfo
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

LIBTINFO_VERSION=5
LIBNCURSESW_VERSION=6.0
LIBDIR="$TARGET_DIR/usr/lib"

ln -fsr "$LIBDIR/libncursesw.so.$LIBNCURSESW_VERSION" \
  "$LIBDIR/libtinfo.so.$LIBTINFO_VERSION"
ln -fsr "$LIBDIR/libtinfo.so.$LIBTINFO_VERSION" "$LIBDIR/libtinfo.so"
