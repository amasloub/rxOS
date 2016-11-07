################################################################################
#
# storage-hotplug
#
################################################################################

STORAGE_HOTPLUG_VERSION = 1.2
STORAGE_HOTPLUG_LICENSE = GPLv3+
STORAGE_HOTPLUG_SITE = $(BR2_EXTERNAL)/local/storage-hotplug/src
STORAGE_HOTPLUG_SITE_METHOD = local

STORAGE_HOTPLUG_SED_CMDS += s|%CHECK_PKG%|$(BR2_STORAGE_HOTPLUG_CHECK_PKG)|;

define STORAGE_HOTPLUG_INSTALL_TARGET_CMDS
	sed -i '$(STORAGE_HOTPLUG_SED_CMDS)' $(@D)/hotplug.storage.sh
	$(INSTALL) -Dm755 $(@D)/hotplug.storage.sh \
		$(TARGET_DIR)/usr/sbin/hotplug.storage
	$(INSTALL) -Dm644 $(@D)/99-storage.rules \
		$(TARGET_DIR)/etc/udev/rules.d/99-storage.rules
endef

$(eval $(generic-package))
