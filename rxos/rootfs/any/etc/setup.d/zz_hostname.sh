#! /bin/sh

[ -f /mnt/conf/etc/hostname] && hostname $(cat /mnt/conf/etc/hostname)
