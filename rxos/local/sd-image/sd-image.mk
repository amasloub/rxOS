################################################################################
#
# sd-image
#
################################################################################

SD_IMAGE_VERSION = 1.0
SD_IMAGE_LICENSE = GPL
SD_IMAGE_SITE = $(BR2_EXTERNAL)/local/sd-image/src
SD_IMAGE_SITE_METHOD = local
SD_IMAGE_DEPENDENCIES += host-dir2fat32 host-cdrkit host-cloop

.PHONY: rebuild-sd-image

ifeq ($(BR2_PACKAGE_SD_IMAGE),y)
BR2_ROOTFS_POST_IMAGE_SCRIPT += $(SD_IMAGE_SITE)/mksdimage.sh
endif

rebuild-sd-image:
	$(SD_IMAGE_SITE)/mksdimage.sh
