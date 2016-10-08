################################################################################
#
# wgrib2bin
#
################################################################################

WGRIB2BIN_VERSION = 1.0
WGRIB2BIN_LICENSE = GPLv3+
WGRIB2BIN_SITE = $(BR2_EXTERNAL)/local/wgrib2bin/src
WGRIB2BIN_SITE_METHOD = local

define WGRIB2BIN_INSTALL_TARGET_CMDS
	$(INSTALL) -Dm755 $(@D)/wgrib2_arm $(TARGET_DIR)/usr/bin/wgrib2
endef

$(eval $(generic-package))
