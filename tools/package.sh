#!/bin/bash
#
# Create a pkg from a directory. The directory should contain, at minimum, an
# executable shell script named ``run.sh``.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

SCRIPT_DIR="$(dirname $0)"
SRC_DIR="$SCRIPT_DIR/.."
HOSTBIN_DIR="$SRC_DIR/out/host/usr/bin"
IMAGES_DIR="$SRC_DIR/out/images"
MKPKG="$HOSTBIN_DIR/mkpkg"
SIGNATURE="$IMAGES_DIR/signature.pem"
PWFILE="$SRC_DIR/.password"
PKGSOURCE="$1"

usage() {
  cat <<EOF
Usage: $0 DIR

Parameters:

  DIR   source directory that should be converted into a .pkg 
        The DIR directory should contain, at minimum, an 
        executable script named run.sh. Directory name is used 
        as the name of the .pkg file.

This script is part of rxOS.
rxOS is free software licensed under the
GNU GPL version 3 or any later version.

(c) 2016 Outernet Inc
Some rights reserved.
EOF
}

fail() {
  local msg="$1"
  echo "ERROR: $msg"
  exit 1
}

if [ -z "$PKGSOURCE" ] || ! [ -d "$PKGSOURCE" ]; then
  echo "ERROR: Missing source directory"
  echo
  usage
  exit 1
fi

PKGNAME="$(basename "$(cd "$PKGSOURCE" && pwd)").pkg"
FILES="$(find "$PKGSOURCE" -mindepth 1 -maxdepth 1)"

if [ -f "$SIGNATURE" ]; then
  if [ -f "$PWFILE" ]; then
    PW="$(cat "$PWFILE")"
  else
    read -srp "Signature key password: " PW
  fi
  [ -z "$PW" ] && fail "Password cannot be empty"
  "$MKPKG" -k "$SIGNATURE" -p "$PW" -o "$PKGNAME" $FILES
else
  "$MKPKG" -o "$PKGNAME" $FILES
fi
