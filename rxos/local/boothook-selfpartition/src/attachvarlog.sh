#!/bin/sh

[ -d /mnt/downloads/.log ] || mkdir /mnt/downloads/.log
ln -s /mnt/downloads/.log /var/log
