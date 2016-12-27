################################################################################
#
# cloop-arm-bin
#
################################################################################

CLOOP_ARM_BIN_VERSION = 1.0
CLOOP_ARM_BIN_SITE = $(BR2_EXTERNAL)/local/cloop-arm-bin/src
CLOOP_ARM_BIN_SITE_METHOD = local

define CLOOP_ARM_BIN_INSTALL_TARGET_CMDS
	$(INSTALL) -Dm755 $(@D)/create_compressed_fs_arm $(TARGET_DIR)/usr/bin/create_compressed_fs
	$(INSTALL) -Dm755 $(@D)/extract_compressed_fs_arm $(TARGET_DIR)/usr/bin/extract_compressed_fs
endef

$(eval $(generic-package))
