################################################################################
#
# persist-conf
#
################################################################################

PERSIST_CONF_VERSION = 1.0
PERSIST_CONF_LICENSE = GPLv3+
PERSIST_CONF_SITE = $(BR2_EXTERNAL)/local/persist-conf/src
PERSIST_CONF_SITE_METHOD = local

PERSISTENT_CONF_LIST += $(call qstrip,$(BR2_PERSISTENT_CONF_LIST))
PERSISTENT_CONF_DIR = $(call qstrip,$(BR2_PERSISTENT_CONF_DIR))

define PERSIST_CONF_INSTALL_TARGET_CMDS
	sed -i 's|%CONFDIR%|$(PERSISTENT_CONF_DIR)|g' $(@D)/persist.sh
	$(INSTALL) -Dm755 $(@D)/persist.sh $(TARGET_DIR)/etc/setup.d/persist.sh
endef

define PERSIST_CONF_INSTALL_LIST_CMDS
	@$(call MESSAGE,"Installing persist.conf")
	printf '$(foreach path,$(PERSISTENT_CONF_LIST),$(path)\n)' \
		| sed 's/^ //' \
		> $(TARGET_DIR)/etc/persist.conf
endef

ifeq ($(BR2_PACKAGE_PERSIST_CONF),y)
TARGET_FINALIZE_HOOKS += PERSIST_CONF_INSTALL_LIST_CMDS
endif

$(eval $(generic-package))
