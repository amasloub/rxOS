#!/bin/sh

[ -d /mnt/downloads/.cache ] || mkdir /mnt/downloads/.cache
ln -s /mnt/downloads/.cache /mnt/cache

[ -d /mnt/downloads/.adata ] || mkdir /mnt/downloads/.adata
ln -s /mnt/downloads/.adata /mnt/data
