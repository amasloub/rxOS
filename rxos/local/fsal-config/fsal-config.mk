################################################################################
#
# fsal-config
#
################################################################################

FSAL_CONFIG_VERSION = 1.2
FSAL_CONFIG_LICENSE = GPL
FSAL_CONFIG_SITE = $(BR2_EXTERNAL)/local/fsal-config/src
FSAL_CONFIG_SITE_METHOD = local

FSAL_BLACKLIST = $(foreach rxp,$(call qstrip,$(BR2_PATH_BLACKLIST)),\n  $(rxp))
FSAL_SED_CMDS += s|%BLACKLIST%|$(FSAL_BLACKLIST)|g;

FSAL_SED_CMDS += s|%SOCKETPATH%|$(call qstrip,$(BR2_FSAL_SOCKETPATH))|g;
FSAL_SED_CMDS += s|%LOGPATH%|$(call qstrip,$(BR2_FSAL_LOGPATH))|g;
FSAL_SED_CMDS += s|%LOGSIZE%|$(call qstrip,$(BR2_FSAL_LOGSIZE))|g;
FSAL_SED_CMDS += s|%LOGBACKUPS%|$(call qstrip,$(BR2_FSAL_LOGBACKUPS))|g;
FSAL_SED_CMDS += s|%BLACKLIST%|$(FSAL_BLACKLIST)|g;

define FSAL_CONFIG_INSTALL_TARGET_CMDS
	$(SED) '$(FSAL_SED_CMDS)' $(@D)/fsal.ini
	$(INSTALL) -Dm644 $(@D)/fsal.ini $(TARGET_DIR)/etc/fsal.ini
endef

$(eval $(generic-package))
