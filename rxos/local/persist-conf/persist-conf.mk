################################################################################
#
# persist-conf
#
################################################################################

PERSIST_CONF_VERSION = 1.0
PERSIST_CONF_LICENSE = GPLv3+
PERSIST_CONF_SITE = $(BR2_EXTERNAL)/local/persist-conf/src
PERSIST_CONF_SITE_METHOD = local

PERSISTENT_CONF_LIST = $(call qstrip,$(BR2_PERSISTENT_CONF_LIST))
PERSISTENT_CONF_DIR = $(call qstrip,$(BR2_PERSISTENT_CONF_DIR))

define PERSIST_CONF_INSTALL_TARGET_CMDS
	sed -i 's|%CONFDIR%|$(PERSISTENT_CONF_DIR)|g' $(@D)/persist.sh
	$(INSTALL) -Dm644 $(@D)/persist.sh $(TARGET_DIR)/etc/setup.d/persist.sh
	$(INSTALL) -Dm644 $(PERSISTENT_CONF_LIST) $(TARGET_DIR)/etc/persist.conf
endef

$(eval $(generic-package))
