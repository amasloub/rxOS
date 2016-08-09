#!/bin/bash
#
# Create OTA update packages for overlays in the output directory.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
# 
# (c) 2016 Outernet Inc
# Some rights reserved.


set -e

BOARD=${BOARD:=chip}
SCRIPTDIR=$(dirname $0)
SRCDIR="${SCRIPTDIR}/.."
OUTDIR="${SRCDIR}/out/${BOARD}"
BINDIR="${OUTDIR}/images"
HOSTDIR="${OUTDIR}/host"
TARGETDIR="${OUTDIR}/target"
MKPKG="${HOSTDIR}/usr/bin/mkpkg"
SIGNATURE="${BINDIR}/signature.pem"
PWFILE="${SRCDIR}/.password"
VERFILE="${TARGETDIR}/etc/version"
VERSION="$(cat "$VERFILE")"
INSTALLER_SRC="${SCRIPTDIR}/overlay-installer.in.sh"

fail() {
  msg="$*"
  echo "ERROR: $msg"
  exit 1
}

usage() {
  cat <<EOF
Usage: $0 [-P]

Options:

  -h    show this message and exit
  -P    do not perform target platform version check
  -I    ignore any installed version and always overwrite

Details:

  When installer runs, by default it checks the platform version
  of the receiver to determine overlay compatibility. This behavior
  can be suppressed by using the -P option.
EOF
}

get_overlay_name() {
  local overlay_basename="$1"
  echo "$overlay_basename" | cut -d- -f2
}

get_overlay_version() {
  local overlay_basename="$1"
  echo "$overlay_basename" | cut -d- -f3
}

package_overlay() {
  local overlay_file="$1"
  local overlay_filename
  local overlay_basename
  local overlay_name
  local overlay_version
  local installer_out
  local pkgfile
  local timestamp
  local version
  local sed_xpr
  local suffix

  # GEt all the variables
  echo "Packaging overlay $overlay_file"
  overlay_filename=$(basename "$overlay_file")""
  overlay_basename="${overlay_filename%%.sqfs}"
  overlay_name=$(get_overlay_name "$overlay_basename")
  overlay_version=$(get_overlay_version "$overlay_basename")
  installer_out="$(mktemp -t overlay-installer-XXXX.sh)"

  # Create the installer script
  sed_xpr="
  s|%OVERLAY_FILE%|${overlay_filename}|;
  s|%OVERLAY_NAME%|${overlay_name}|;
  s|%TARGET_VERSION%|${TARGET_VERSION}|;"
  if [ "$IGNORE_VERSION" = y ]; then
    sed_xpr="$sed_xpr s|%OVERLAY_VERSION%||;"
    suffix="nv"
  else
    sed_xpr="$sed_xpr s|%OVERLAY_VERSION%|${overlay_version}|;"
  fi
  sed -e  "$sed_xpr" > "$installer_out" < "$INSTALLER_SRC"

  # Create the .pkg file
  if [ "$TARGET_VERSION" = any ]; then
    version=any
  else
    version="v${TARGET_VERSION}"
  fi
  timestamp="$(date '+%Y%m%d%H%M')"
  pkgfile="$BINDIR/rxos-${version}_overlay-${overlay_name}-v${overlay_version}-${timestamp}${suffix}.pkg"
  chmod +x "$installer_out"
  $MKPKG $MKPKG_ARGS -o "$pkgfile" "${installer_out}:run.sh" "${overlay_file}"
  rm -f "$installer_out"
}

[ -x "$MKPKG" ] || fail "mkpkg not found, please complete the build first"

[ -f "$SIGNATURE" ] && MKPKG_ARGS="-k $SIGNATURE"

while getopts "hPI" opt; do
  case "$opt" in
    h)
      usage
      exit 0
      ;;
    P)
      IGNORE_PLATFORM=y
      ;;
    I)
      IGNORE_VERSION=y
      ;;
    *)
      fail "invalid option $opt"
      ;;
  esac
done

if [ "$IGNORE_PLATFORM" != y ]; then
  TARGET_VERSION="$VERSION"
else
  TARGET_VERSION="any"
fi

if [ -f "$PWFILE" ]; then
  PASSWORD="$(cat "$PWFILE")"
else
  read -srp "Signature file password: " PASSWORD
fi

[ -n "$PASSWORD" ] && MKPKG_ARGS="$MKPKG_ARGS -p $PASSWORD"

find "$BINDIR/overlays/" -name "overlay-*.sqfs" | while read -r overlay; do
  package_overlay "$overlay"
done
