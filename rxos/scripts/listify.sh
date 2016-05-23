#!/bin/bash
#
# Convert arguments to a format that can be used in sed scripts that need to
# fill in the confloader lists.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

for arg in "$@"; do
  echo -n "    $arg\n"
done
