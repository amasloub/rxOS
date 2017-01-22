################################################################################
#
# dtc-tools
#
################################################################################

DTC_TOOLS_VERSION = 0931cea
DTC_TOOLS_SITE = https://github.com/Outernet-Project/dtc
DTC_TOOLS_SITE_METHOD = git
DTC_TOOLS_DEPENDENCIES = linux

define DTC_TOOLS_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) CC=$(TARGET_CC) -C $(@D)
endef

define DTC_TOOLS_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/fdtput $(TARGET_DIR)/usr/bin/fdtput
	$(INSTALL) -m 0755 -D $(@D)/fdtget $(TARGET_DIR)/usr/bin/fdtget
	$(INSTALL) -m 0755 -D $(@D)/fdtdump $(TARGET_DIR)/usr/bin/fdtdump
endef

$(eval $(generic-package))

