#!/bin/bash
#
# Collect static assets from Librarian components into Librarian's own static
# assets directory. The source assets are not copied but symlinked to prevent
# duplication. Only static assets other than CSS and JS are collected (e.g.,
# fonts, images, etc). The CSS and JS assets are collected dynamically by
# webassets at runtime.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

set -e

SCRIPTDIR="$(dirname "$0")"
. "$SCRIPTDIR/helpers.sh"

SITES="$TARGET_DIR/usr/lib/python2.7/site-packages"
COLLECT_TO="$SITES/librarian/static"

# Return the specified path as path relative to a parent path
#
# Arugments:
#
#   path:   source path
#   par:    parent path
relpath() {
    path=$1
    par=$2
    echo "${path##$par/}"
}

# Find all static directories in all libarian components
for d in "$SITES"/librarian_*/static; do
  msg "Collecting static assets in '$d'"
  find "$d" -type f -not \( -name "*.css" -or -name "*.js" \) | while read -r target; do
      relname="$(relpath "$target" "$d")"
      linkname="$COLLECT_TO/$relname"
      mkdir -p "$(dirname "$linkname")"
      ln -sr "$target" "$linkname" || exit 1
      submsg "Symlinked $linkname"
    done
done
