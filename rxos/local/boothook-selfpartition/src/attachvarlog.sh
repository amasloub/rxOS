#!/bin/sh

[ -d /mnt/downloads/.log ] || mkdir /mnt/downloads/.log
[ -L /var/log ] && unlink /var/log
ln -s /mnt/downloads/.log /var/log
