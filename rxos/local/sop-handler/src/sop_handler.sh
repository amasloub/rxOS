#!/bin/sh

# (C) 2016 Outernet Inc

set -euf

# ORIG_SOP_FILE has a signature block prepended
ORIG_SOP_FILE="$1"
# SOP_FILE is post-verification, no signature block
SOP_FILE="$1"

# manifest is formatted like this:
# install_method filename installparam1 installparam2 ...

# example manifest:
# part_cp zImage /boot no_compress
# part_cp sun5i-r8-chip.dtb /boot no_compress
# mtd_nandwrite uboot.bin uboot
# part_cp sunxi-spl-with-ecc.bin /boot no_compress
# part_cp rootfs.tar /boot post_compress

sign_verify() {
    tmploc="/mnt/data"
    SOP_FILE="$tmploc/$(basename $ORIG_SOP_FILE)"
    if tweetnacl-verify %SOPSIGNPUBKEY% $ORIG_SOP_FILE $SOP_FILE
    then
        echo SOP verified
    else
        echo SOP failed verification
        exit 1
    fi
}

sop_validate() {
    sign_verify
    # check if has manifest
    tar tf "$SOP_FILE" "manifest" >/dev/null 2>&1 || exit 1
}

sop_extract() {
    fn="$1"
    tar Oxf "$SOP_FILE" "$fn"
}

part_cp() {
    loc="$2"
    fn="$1"
    post_compress="$3"
    partmode=$(mount | grep "$loc" | tr '(' , | cut -d , -f 2)
    [ "$partmode" = "ro" ] && mount -o remount,rw "$loc"
    if [ "$post_compress" = "post_compress" ]
    then
        sop_extract "$fn" | gzip -c > "${loc}/${fn}.gz"
    else
        sop_extract "$fn" > "$loc"/"$fn"
    fi
    sync; sync; sync;
    [ "$partmode" = "ro" ] && mount -o remount,ro "$loc"
}

free_space() {
    part="$1"
    echo $(( $(df -m "$part" | tail -n 1 | sed 's/  */ /g' | cut -d " " -f 4) * 1024 * 1024))
}

mtd_nandwrite() {
    part_name="$2"
    fn="$1"
    part_dev="/dev/$(cat /proc/mtd | grep $part_name | cut -d : -f 1 | head -n 1 )"
    flash_erase "$part_dev" 0 0
    sop_extract "$fn" | nandwrite -p "$part_dev" -
}

sop_store() {
    loc="/boot"
    fn="$1"
    partmode=$(mount | grep "$loc" | tr '(' , | cut -d , -f 2)
    [ "$partmode" = "ro" ] && mount -o remount,rw "$loc"
    fsize=$(stat -c %s "$fn")
    while [  $(free_space $loc)  -lt  $fsize ]
    do
        rm $(ls "$loc/*.sop" | sort | head -n 1)
    done
    gzip -c "$fn" > "$loc/$(basename $fn)"
    sync; sync; sync;
    [ "$partmode" = "ro" ] && mount -o remount,ro "$loc"
}

psop_apply() {
    loc="/boot"
    tmploc="/mnt/data"
    #psops are named: prefix.stamp.to.stamp.psop
    prefix=$( echo "$SOP_FILE"  | cut -d "." -f 1)
    src_sop_stamp=$( echo "$SOP_FILE"  | cut -d "." -f 2)
    src_sop="$prefix.$src_sop_stamp.sop"
    gunzip -c "$loc/$src_sop" > "$tmploc/src_sop"
    dest_sop_stamp=$( echo "$SOP_FILE"  | cut -d "." -f 4)
    dest_sop="$prefix.$dest_sop_stamp.sop"
    if [ -f "$tmploc/$src_sop" ]
    then
        echo "Applying PSOP to $loc/$src_sop"
        bspatch "$tmploc/$src_sop" "$tmploc/$dest_sop" "$SOP_FILE"
        if [ -f "$tmploc/$dest_sop" ]
        then
            echo "Patched. Activating patched SOP"
            mv "$tmploc/$dest_sop" %SOPSOURCE%
        else
            echo "Patching failed"
        fi
    else
        echo "Could not find Source SOP $loc/$src_sop to apply partial sop $SOP_FILE"
    fi
    echo "Cleaning up $SOP_FILE"
    rm "$tmploc/$src_sop"
    rm "$SOP_FILE"
}

sop_apply() {
    sop_validate
    eval "$(sop_extract manifest)"
    sop_store "$ORIG_SOP_FILE"
    rm "$ORIG_SOP_FILE"
}

xzsop_apply() {
    tmploc="/mnt/data"
    unxz_sop_fn="$tmploc/$(basename ${ORIG_SOP_FILE/.xz})"
    unxz -c "$ORIG_SOP_FILE" > "$unxz_sop_fn"
    rm "$ORIG_SOP_FILE"
    mv  "$unxz_sop_fn" "$(dirname $ORIG_SOP_FILE)"
}

if [ $(expr "$SOP_FILE" : ".*\.psop$") -gt 0 ]
then
    psop_apply
elif [ $(expr "$SOP_FILE" : ".*\.xz.sop$") -gt 0 ]
then
    xzsop_apply
else
    sop_apply
fi
