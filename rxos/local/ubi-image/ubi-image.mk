################################################################################
#
# ubi-image
#
################################################################################

UBI_IMAGE_VERSION = 1.0
UBI_IMAGE_LICENSE = GPL
UBI_IMAGE_SITE = $(BR2_EXTERNAL)/local/ubi-image/src
UBI_IMAGE_SITE_METHOD = local
UBI_IMAGE_DEPENDENCIES += host-mtd-mlc

UBINIZE_CFG_SED_CMDS += s|BINARIES_DIR|$(BINARIES_DIR)|g;

# change this to '/dev/urandom' to get normal, not-reproducible behaviour
UBI_IMAGE_RANDOM_SOURCE = $(BINARIES_DIR)/spl-image-builder-random-source.bin
UBI_IMAGE_RANDOM_SOURCE_SED_CMDS = s|/dev/urandom|$(UBI_IMAGE_RANDOM_SOURCE)|g;

ifeq ($(BR2_PACKAGE_UBI_IMAGE),y)
BR2_ROOTFS_POST_IMAGE_SCRIPT += $(UBI_IMAGE_SITE)/mkubi.sh
endif

define UBI_IMAGE_BUILD_CMDS
	$(SED) '$(UBI_IMAGE_RANDOM_SOURCE_SED_CMDS)' $(@D)/sunxi-spl-image-builder.c
	$(HOSTCC) -o $(@D)/spl-image-builder $(@D)/sunxi-spl-image-builder.c
endef

define UBI_IMAGE_INSTALL_TARGET_CMDS
	$(SED) '$(UBINIZE_CFG_SED_CMDS)' $(@D)/ubinize.cfg
	$(INSTALL) -Dm644 $(@D)/ubinize.cfg $(BINARIES_DIR)/ubinize.cfg
	$(INSTALL) -Dm755 $(@D)/spl-image-builder $(BINARIES_DIR)/spl-image-builder
	$(INSTALL) -Dm644 $(@D)/spl-image-builder-random-source.bin $(BINARIES_DIR)/spl-image-builder-random-source.bin
endef

$(eval $(generic-package))

rebuild-ubi:
	$(UBI_IMAGE_SITE)/mkubi.sh
