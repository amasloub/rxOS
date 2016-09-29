################################################################################
#
# opakwatch
#
################################################################################

OPAKWATCH_VERSION = 1.0
OPAKWATCH_LICENSE = GPLv3+
OPAKWATCH_SITE = $(BR2_EXTERNAL)/local/opakwatch/src
OPAKWATCH_SITE_METHOD = local

OPAKWATCH_SED_CMDS += s|%OPAKSOURCE%|$(call qstrip,$(BR2_OPAKWATCH_SOURCE))|;
OPAKWATCH_SED_CMDS += s|%OPAKDESTINATION%|$(call qstrip,$(BR2_OPAKWATCH_DESTINATION))|;

define OPAKWATCH_INSTALL_TARGET_CMDS
	$(INSTALL) -Dm755 $(@D)/opakwatch.sh $(TARGET_DIR)/usr/bin/opakwatch
endef

define OPAKWATCH_INSTALL_INIT_SYSV
	$(INSTALL) -Dm0755 $(@D)/S99opakwatch $(TARGET_DIR)/etc/init.d/S99opakwatch
	$(SED) '$(OPAKWATCH_SED_CMDS)' $(TARGET_DIR)/etc/init.d/S99opakwatch
endef

$(eval $(generic-package))
