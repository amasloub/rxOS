################################################################################
#
# opakwatch2
#
################################################################################

OPAKWATCH2_VERSION = 1.0
OPAKWATCH2_LICENSE = GPLv3+
OPAKWATCH2_SITE = $(BR2_EXTERNAL)/local/opakwatch2/src
OPAKWATCH2_SITE_METHOD = local

OPAKWATCH2_SED_CMDS += s|%OPAKSOURCE%|$(call qstrip,$(BR2_OPAKWATCH2_SOURCE))|;
OPAKWATCH2_SED_CMDS += s|%OPAKDESTINATION%|$(call qstrip,$(BR2_OPAKWATCH2_DESTINATION))|;

define OPAKWATCH2_INSTALL_TARGET_CMDS
	$(INSTALL) -Dm755 $(@D)/opakhandler $(TARGET_DIR)/usr/bin/opakhandler
	$(INSTALL) -Dm0644 $(@D)/opaks.incron $(TARGET_DIR)(call qstrip,$(BR2_INCRON_CONFDIR))/opaks.incron
	$(SED) '$(OPAKWATCH2_SED_CMDS)' $(TARGET_DIR)(call qstrip,$(BR2_INCRON_CONFDIR))/opaks.incron
endef

$(eval $(generic-package))
