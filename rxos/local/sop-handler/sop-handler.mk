################################################################################
#
# sop-handler
#
################################################################################

SOP_HANDLER_VERSION = 1.0
SOP_HANDLER_SITE = $(BR2_EXTERNAL)/local/sop-handler/src
SOP_HANDLER_SITE_METHOD = local

SOP_HANDLER_SED_CMDS += s|%SOPSOURCE%|$(call qstrip,$(BR2_SOP_HANDLER_SOURCE))|;
SOP_HANDLER_SED_CMDS += s|%SOPSIGNPUBKEY%|$(call qstrip,$(BR2_SOP_SIGN_PUBKEY_PATH))|;

define SOP_HANDLER_INSTALL_TARGET_CMDS
	$(INSTALL) -Dm755 $(@D)/sop_handler.sh $(TARGET_DIR)/usr/bin/sop_handler
	$(SED) '$(SOP_HANDLER_SED_CMDS)' $(TARGET_DIR)/usr/bin/sop_handler
	$(INSTALL) -Dm0644 $(@D)/sop.incron $(TARGET_DIR)$(call qstrip,$(BR2_INCRON_SERVICE_CONFDIR))/sop.incron
	$(SED) '$(SOP_HANDLER_SED_CMDS)' $(TARGET_DIR)$(call qstrip,$(BR2_INCRON_SERVICE_CONFDIR))/sop.incron
	$(INSTALL) -Dm0644 $(@D)/sop.pubkey $(TARGET_DIR)$(call qstrip,$(BR2_SOP_SIGN_PUBKEY_PATH))/sop.pubkey
endef

$(eval $(generic-package))
