#!/bin/sh

multifs -o nonempty,allow_other /mnt/external,/mnt/internal /mnt/downloads
mount -o bind /mnt/internal /mnt/external
