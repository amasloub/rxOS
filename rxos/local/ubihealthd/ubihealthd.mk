################################################################################
#
# ubihealthd
#
################################################################################

UBIHEALTHD_VERSION = 0.1
UBIHEALTHD_SITE = $(BR2_EXTERNAL)/local/ubihealthd/src
UBIHEALTHD_SITE_METHOD = local


define UBIHEALTHD_INSTALL_TARGET_CMDS
endef

define UBIHEALTHD_INSTALL_INIT_SYSV
	$(INSTALL) -Dm0755 $(@D)/S80ubihealthd $(TARGET_DIR)/etc/init.d/S80ubihealthd
endef

$(eval $(generic-package))
