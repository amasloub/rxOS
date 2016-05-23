################################################################################
#
# nginx-config
#
################################################################################

POSTGRES_CONFIG_VERSION = 1.0
POSTGRES_CONFIG_LICENSE = GPL
POSTGRES_CONFIG_SITE = $(BR2_EXTERNAL)/local/postgres-config/src
POSTGRES_CONFIG_SITE_METHOD = local

POSTGRES_SED_CMDS += s|%DBDIR%|$(call qstrip,$(BR2_POSTGRES_DBDIR))|;
POSTGRES_SED_CMDS += s|%USER%|$(call qstrip,$(BR2_POSTGRES_USER))|;

define POSTGRES_CONFIG_INSTALL_TARGET_CMDS
	sed -i '$(POSTGRES_SED_CMDS)' $(@D)/S50postgresql
	$(INSTALL) -Dm0755 $(@D)/S50postgresql \
		$(TARGET_DIR)/etc/init.d/S50postgresql
endef

$(eval $(generic-package))
