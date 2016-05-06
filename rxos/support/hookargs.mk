# Pass build hook arguments
# 
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

ifeq ($(BR2_CPIO_COMPRESSION),"")
CPIO_COMPRESSION=none
else
CPIO_COMPRESSION=$(BR2_CPIO_COMPRESSION)
endif

ifeq ($(RXOS_BUILD_SDIMAGE), y)
SDSIZE = $(call qstrip,$(RXOS_SDIMAGE_SIZE))
SDSOURCE = $(call qstrip,$(RXOS_SDIMAGE_SOURCE))
SDNAME = $(call qstrip,$(RXOS_SDIMAGE_FILE))
else
SDSIZE = 0
SDSOURCE = none
SDNAME = none
endif

BR2_ROOTFS_POST_SCRIPT_ARGS = $(RXOS_PLATFORM) \
							  $(RXOS_VERSION) \
							  $(BR2_LINUX_KERNEL_VERSION) \
							  $(CPIO_COMPRESSION) \
							  $(BR2_CPIO_COMPRESSED_FILE) \
							  $(RXOS_TMPFS_SIZE) \
							  $(SDSIZE) \
							  $(SDSOURCE) \
							  $(SDNAME)

print-post-script-args:
	@echo $(BR2_ROOTFS_POST_SCRIPT_ARGS)
