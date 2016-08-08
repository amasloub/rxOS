################################################################################
#
# sdimage
#
################################################################################

SDIMAGE_VERSION = 1.0
SDIMAGE_LICENSE = GPL
SDIMAGE_SITE = $(BR2_EXTERNAL)/local/sdimage/src
SDIMAGE_SITE_METHOD = local

ifeq ($(BR2_PACKAGE_SDIMAGE),y)
BR2_ROOTFS_POST_IMAGE_SCRIPT += $(call lpkgdir,sdimage)/src/mksdimage.sh
endif
