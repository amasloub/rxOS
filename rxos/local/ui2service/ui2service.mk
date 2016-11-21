################################################################################
#
# ui2service
#
################################################################################

UI2SERVICE_VERSION = 0.3
UI2SERVICE_SITE = $(BR2_EXTERNAL)/local/ui2service/src
UI2SERVICE_SITE_METHOD = local


define UI2SERVICE_INSTALL_TARGET_CMDS
endef

define UI2SERVICE_INSTALL_INIT_SYSV
	$(INSTALL) -Dm0755 $(@D)/S70ui2service $(TARGET_DIR)/etc/init.d/S70ui2service
endef

$(eval $(generic-package))
