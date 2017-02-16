#!/bin/bash
#
# patch the target dir with various parts of KEY_RELEASE to minimize OTA size
#
# (c) 2016 Outernet Inc
# Some rights reserved.

set -eu

kept_files="usr/lib/libgcrypt.so.20.0.4 usr/lib/libgpg-error.so.0.10.0 lib/modules usr/share/zoneinfo"

# this directory shows up in some builds for no reason, and doesn't in others
rmdir -f "${BINARIES_DIR}/../target/usr/etc"

if [ -z "$KEY_RELEASE" ]
then
    echo "Key release: OTA hack"
    # build the modules package for later use with nasty ota hack when building deltas
    tar zcf "$BINARIES_DIR/kept_files.tgz" --hard-dereference -C "${BINARIES_DIR}/../target/" $kept_files
    (cd "${BINARIES_DIR}/../target" && rm -rf $kept_files)
    tar xf "${BINARIES_DIR}/kept_files.tgz" -C "${BINARIES_DIR}/../target"
else
    echo "Delta release: OTA hack"
    cp "${BINARIES_DIR}/../../../../rxos_builds/RELEASES/${KEY_RELEASE}/zImage" "$LINUX"
    (cd "${BINARIES_DIR}/../target" && rm -rf $kept_files)
    tar xf "${BINARIES_DIR}/../../../../rxos_builds/RELEASES/${KEY_RELEASE}/kept_files.tgz" -C "${BINARIES_DIR}/../target"
fi
