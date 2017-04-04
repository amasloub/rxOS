################################################################################
#
# setup
#
################################################################################

SETUP_VERSION = 1.0
SETUP_LICENSE = GPLv3+
SETUP_SITE = $(BR2_EXTERNAL)/local/setup/src
SETUP_SITE_METHOD = local

define SETUP_INSTALL_TARGET_CMDS
	$(INSTALL) -Dm755 $(@D)/S00setup $(TARGET_DIR)/etc/init.d/S00setup
	$(INSTALL) -dm755 $(TARGET_DIR)/etc/setup.d
    $(INSTALL) -Dm755 $(@D)/early-setup.sh.$(BOARD) $(TARGET_DIR)/usr/sbin/early-setup.sh
endef

$(eval $(generic-package))
