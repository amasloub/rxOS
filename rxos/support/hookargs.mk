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

ifeq ($(BR2_PACKAGE_SDIMAGE), y)
SDSIZE = $(BR2_SDIMAGE_SIZE)
SDSOURCE = $(call qstrip,$(BR2_SDIMAGE_SOURCE))
SDNAME = $(call qstrip,$(BR2_SDIMAGE_FILE))
else
SDSIZE = 0
SDSOURCE = none
SDNAME = none
endif

ifeq ($(BR2_OTA_PKG_VERSIONLESS), y)
VERSIONED_PKG = y
else
VERSIONED_PKG = n
endif

BR2_ROOTFS_POST_SCRIPT_ARGS = $(RXOS_PLATFORM) \
							  $(RXOS_SUBPLATFORM) \
							  $(RXOS_VERSION) \
							  $(BR2_LINUX_KERNEL_VERSION) \
							  $(CPIO_COMPRESSION) \
							  $(BR2_CPIO_COMPRESSED_FILE) \
							  $(RXOS_TMPFS_SIZE) \
							  $(SDSIZE) \
							  $(SDSOURCE) \
							  $(SDNAME) \
							  $(VERSIONED_PKG)

.PHONY: print-post-script-args

print-post-script-args:
	@echo $(BR2_ROOTFS_POST_SCRIPT_ARGS)
