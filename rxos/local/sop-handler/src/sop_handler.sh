#!/bin/sh

# (C) 2016 Outernet Inc

set -euf

# ORIG_SOP_FILE has a signature block prepended
# SOP_FILE is post-verification, no signature block
SOP_FILE="$1"

sopmpt="/tmp/sopmpt" # sop mount point

tmploc=$(mktemp -d -p /mnt/data/)
# manifest is formatted like this:
# install_method filename installparam1 installparam2 ...

# example manifest:
# part_cp zImage /boot
# part_cp sun5i-r8-chip.dtb /boot
# mtd_nandwrite uboot.bin uboot
# part_cp sunxi-spl-with-ecc.bin /boot
# part_cp rootfs.tar /boot
# sop_store_key

clean_exit() {
    rm -rf $tmploc
    echo "Exit with errors"
    exit $1
}

sign_verify() {
    if tweetnacl-verify %SOPSIGNPUBKEY% $SOP_FILE - > /dev/null
    then
        echo SOP verified
    else
        echo SOP failed verification
        clean_exit 1
    fi
}

sop_validate() {
    sign_verify
}

part_cp() {
    loc="$2"
    fn="$1"
    partmode=$(mount | grep "$loc" | tr '(' , | cut -d , -f 2)
    [ "$partmode" = "ro" ] && mount -o remount,rw "$loc"
    cp "$sopmpt/$fn" "$loc"/"$fn"
    sync; sync; sync;
    [ "$partmode" = "ro" ] && mount -o remount,ro "$loc"
    echo
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
    nandwrite -p "$part_dev" "$sopmpt/$fn"
}

sop_store_key() {
    loc="/boot"
    fn="$SOP_FILE"
    partmode=$(mount | grep "$loc" | tr '(' , | cut -d , -f 2)
    [ "$partmode" = "ro" ] && mount -o remount,rw "$loc"
    fsize=$(stat -c %s "$fn")
    base_fn="$(basename $fn)"
    stored_fn="${base_fn/.sop/.ksop}"
    cp "$fn" > "$loc/$stored_fn"
    sync; sync; sync;
    [ "$partmode" = "ro" ] && mount -o remount,ro "$loc"
    echo
}

sop_store() {
    loc="/boot"
    fn="$SOP_FILE"
    partmode=$(mount | grep "$loc" | tr '(' , | cut -d , -f 2)
    [ "$partmode" = "ro" ] && mount -o remount,rw "$loc"
    fsize=$(stat -c %s "$fn")
    base_fn="$(basename $fn)"
    cp "$fn" > "$loc/$base_fn"
    sync; sync; sync;
    [ "$partmode" = "ro" ] && mount -o remount,ro "$loc"
    echo
}

psop_apply() {
    loc="/boot"
    #psops are named: prefix.stamp.to.stamp.psop
    prefix=$(basename "$SOP_FILE" | cut -d . -f 1)
    src_sop_stamp=$(basename "$SOP_FILE" | cut -d . -f 2)
    src_sop="$prefix$src_sop_stamp.sop"
    src_ksop="$prefix$src_sop_stamp.ksop"
    dest_sop_stamp=$(basename "$SOP_FILE" | cut -d . -f 4)
    dest_sop="$prefix$dest_sop_stamp.sop"

    if [ -f "$src_sop" ]
    then
        src_sop="$src_sop"
    fi

    if [ -f "$src_ksop" ]
    then
        src_sop="$src_ksop"
    fi
    
    if [ -f "$loc/$src_sop" ]
    then
        echo "Applying PSOP to $loc/$src_sop"
        bspatch "$loc/$src_sop" "$tmploc/$dest_sop" "$SOP_FILE"
        if [ -f "$tmploc/$dest_sop" ]
        then
            echo "Patched. Activating patched SOP"
            mv "$tmploc/$dest_sop" $(dirname "$SOP_FILE")/${dest_sop}
        else
            echo "Patching failed"
	        clean_exit 1
        fi
    else
	    echo "Could not find source SOP $loc/$src_sop to apply partial sop $SOP_FILE"
	    clean_exit 1
    fi
    echo "Cleaning up $SOP_FILE"
    rm -f "$SOP_FILE"
}

sop_apply() {
    sop_validate
    [ -d "$sopmpt" ] && rm -rf "$sopmpt"
    mkdir "$sopmpt"
    mount -o loop,offset=64 "$SOP_FILE"  "$sopmpt"
    source "${sopmpt}/manifest"
    umount "$sopmpt"
    rm "$SOP_FILE"
}

xzsop_apply() {
    base_fn="$(basename ${SOP_FILE})"
    unxz_sop_fn="$tmploc/${base_fn/.xz}"
    unxz -c "$SOP_FILE" > "$unxz_sop_fn"
    rm "$SOP_FILE"
    mv  "$unxz_sop_fn" "$(dirname $SOP_FILE)"
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

rm -rf "$tmploc"

