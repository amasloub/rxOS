#!/bin/sh

ARCH=$(uname -m)
DEMOD_DIR="/opt/sdr.d/$ARCH"
DEVICE_ID_DB="$DEMOD_DIR/device_ids.txt"
DEMOD_SYMLINK=/opt/sdr
DEMOD_VERSION_CONF=/mnt/conf/demod.version
RADIO=""

log() {
    >&2 echo "setup_demod: " "$@"
}

radio_devices() {
    lsusb | cut -d " " -f 6 | tr A-F a-f | while read -r dev_id
    do
        grep "$dev_id" "$DEVICE_ID_DB" | cut -d ";" -f 2
    done
}

detect_radio() {
    RADIOS="$(radio_devices)"
    NUM_RADIOS=$(echo "$RADIOS" | wc -c)
    if [ "$NUM_RADIOS" != 15 ]
    then
        log "Less than 1 or more than 1 supported radios. Bailing."
        exit 1
    else
        log "Found $RADIOS"
    fi
    RADIO="$RADIOS"
}

enable_demod() {
    ln -s "$1" "$DEMOD_SYMLINK"
}

setup_demod() {
    detect_radio
	# if demod_version_conf file exists and that version exists, use that
    if [ -f "$DEMOD_VERSION_CONF" ]
    then
        DEMOD_VERSION=$(cat "$DEMOD_VERSION_CONF")
        if [ -d "${DEMOD_DIR}/${RADIO}-${DEMOD_VERSION}" ]
        then
            enable_demod "${DEMOD_DIR}/${RADIO}-${DEMOD_VERSION}"
            log "Enabled ${RADIO}-${DEMOD_VERSION} as per config"
            exit 0
        fi
    fi
    # otherwise use the highest sorting version
    # note that this means final releases must be tagged with "r"
    # eg. starsdr-rtlsdr-2.1r
    NUM_DEMODS=$(ls "${DEMOD_DIR}" | grep "${RADIO}" | sort | tail -n 1 | wc -l)
    if [ ${NUM_DEMODS} == 1 ]
    then
        DEMOD=$(ls "${DEMOD_DIR}" | grep "${RADIO}" | sort | tail -n 1)
        enable_demod "${DEMOD_DIR}/${DEMOD}"
        log "Enabled ${DEMOD} - latest availble version"
    else
        log "could not find any demods for ${RADIO}"
        exit 1
    fi
}

setup_demod
