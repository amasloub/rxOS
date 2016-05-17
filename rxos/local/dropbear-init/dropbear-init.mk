################################################################################
#
# dropbear-init
#
################################################################################

DROPBEAR_INIT_VERSION = 1.0
DROPBEAR_INIT_LICENSE = GPLv3+
DROPBEAR_INIT_SITE = $(BR2_EXTERNAL)/local/dropbear-init/src
DROPBEAR_INIT_SITE_METHOD = local

define DROPBEAR_INIT_INSTALL_TARGET_CMDS
	-rm $(TARGET_DIR)/etc/dropbear
	mkdir -p $(TARGET_DIR)/etc/dropbear
	$(INSTALL) -Dm755 $(@D)/S50dropbear $(TARGET_DIR)/etc/init.d/S50dropbear
endef

$(eval $(generic-package))
