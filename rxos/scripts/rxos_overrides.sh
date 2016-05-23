#!/bin/bash
#
# Rename files that end in .rxos extenion to names without the extension
#
# Some of the local packages will install files that end in .rxos. These files
# are meant to replaces files that are added by Buildroot *after* packages are
# installed, that would normally be overwritten if installed with default 
# names.
#
# This script should be run as a post-build hook.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
# 
# (c) 2016 Outernet Inc
# Some rights reserved.

set -e

SCRIPTDIR=$(dirname $0)
. $SCRIPTDIR/helpers.sh

find "$TARGET_DIR" -name *.rxos | while read f; do
  msg "Renaming '$f'"
  mv "$f" "$(echo "$f" | sed 's/\.rxos//')"
done
