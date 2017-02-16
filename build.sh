#!/bin/bash


base=$(basename $0)

export BOARD=$(echo $base | cut -d - -f 2)
export PRODUCT=$(echo $base | cut -d - -f 1)

# this prevents building at the wrong path
# if you are not building for release feel free to remove the exit line

if [ "$PWD" != "/builds/rxos/rxos" ]
then
    echo 'Releases MUST be built in /builds/rxos/rxos!'
    echo '  otherwise delta updates will be massive.'
    echo
    echo 'Stubbornly refusing to proceed. thbbt!'
    echo '(feel free to comment out the exit line here '
    echo 'in this script to proceed, if you insist. boo!)'
    exit 1
fi


# Set KEY_RELEASE to the last key release path under ../rxos_builds/RELEASES
# if unset, _this_ build will build a key release
KEY_RELEASE_chip="skylark-chip-build-v4.4-1702161550+7ca161f"
KEY_RELEASE_dc="skylark-dc-build-v4.4-1702161551+7ca161f"
KEY_RELEASE=KEY_RELEASE_${BOARD}
KEY_RELEASE=${!KEY_RELEASE}

if [ -n "${KEY_RELEASE}" ]
then
    echo "Building Delta release"
    if [ ! -d "../rxos_builds/RELEASES/${KEY_RELEASE}" ]
    then
        echo "KEY_RELEASE is set to ${KEY_RELEASE} but the release does not exist in ../rxos_builds/RELEASES"
        echo "cannot continue. bailing."
        exit 1
    fi
else
    echo "Building KEY release"
fi

export KEY_RELEASE

# for uboot and ramfsinit
# date -u --date="2017-01-01" +%s
export SOURCE_DATE_EPOCH=1483228800

# for kernel and gen_initramfs
export KBUILD_BUILD_TIMESTAMP=2017-01-01
export KBUILD_BUILD_VERSION=1

# for busybox config
export KCONFIG_NOTIMESTAMP=1

# for mkuser
export MKPASSWD_SALT=mgfYRgrU

# for build timestamps
export RXOS_TIMESTAMP="$(date -u --rfc-3339=seconds)"

[ -d rxos/overlays ] || mkdir rxos/overlays/

if [ $# -gt  0 ]
then
time make BOARD=$BOARD \
    PRODUCT=$PRODUCT \
    RXOS_TIMESTAMP="\"$RXOS_TIMESTAMP\"" \
    KEY_RELEASE=$KEY_RELEASE \
    MKPASSWD_SALT=$MKPASSWD_SALT \
    KCONFIG_NOTIMESTAMP=$KCONFIG_NOTIMESTAMP \
    KBUILD_BUILD_VERSION=$KBUILD_BUILD_VERSION \
    KBUILD_BUILD_TIMESTAMP=$KBUILD_BUILD_TIMESTAMP \
    SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH \
    "$@"
echo "$@" done
else
time make BOARD=$BOARD \
    PRODUCT=$PRODUCT \
    RXOS_TIMESTAMP="\"$RXOS_TIMESTAMP\"" \
    KEY_RELEASE=$KEY_RELEASE \
    MKPASSWD_SALT=$MKPASSWD_SALT \
    KCONFIG_NOTIMESTAMP=$KCONFIG_NOTIMESTAMP \
    KBUILD_BUILD_VERSION=$KBUILD_BUILD_VERSION \
    KBUILD_BUILD_TIMESTAMP=$KBUILD_BUILD_TIMESTAMP \
    SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH \
    build release
fi
