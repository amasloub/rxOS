#!/bin/bash
#
# Generate Librarian emergency token.
#
# This file is part of rxOS.
# rxOS is free software licensed under the 
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

read -n7 -r -p "Enter a 7-digit emergency token (Ctrl-C to quit): " token
echo
echo -n "$token" | sha256sum | awk '{print $1}'
