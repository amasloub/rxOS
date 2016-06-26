################################################################################
#
# ubi-image
#
################################################################################

UBI_IMAGE_VERSION = 1.0
UBI_IMAGE_LICENSE = GPL
UBI_IMAGE_SITE = $(BR2_EXTERNAL)/local/ubi-image/src
UBI_IMAGE_SITE_METHOD = local
UBI_IMAGE_DEPENDENCIES += host-mtd

UBINIZE_CFG_SED_CMDS += s|BINARIES_DIR|$(BINARIES_DIR)|g;

ifeq ($(BR2_PACKAGE_UBI_IMAGE),y)
BR2_ROOTFS_POST_IMAGE_SCRIPT += $(UBI_IMAGE_SITE)/mkubi.sh
endif

define UBI_IMAGE_INSTALL_TARGET_CMDS
	$(SED) '$(UBINIZE_CFG_SED_CMDS)' $(@D)/ubinize.cfg
	$(INSTALL) -Dm644 $(@D)/ubinize.cfg $(BINARIES_DIR)/ubinize.cfg
endef

$(eval $(generic-package))
