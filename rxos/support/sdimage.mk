# Add mksdimage.sh post-image hook if the RXOS_BUILD_SDIMAGE flag is set.
# 
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

ifeq ($(RXOS_BUILD_SDIMAGE),y)
BR2_ROOTFS_POST_IMAGE_SCRIPT += $(BR2_EXTERNAL)/scripts/mksdimage.sh
endif
