#!/bin/sh

multifs /mnt/external,/mnt/internal /mnt/downloads
mount -o bind /mnt/internal /mnt/external
