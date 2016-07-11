################################################################################
#
# rxos-utils
#
################################################################################

RXOS_UTILS_VERSION = 1.0
RXOS_UTILS_LICENSE = GPLv3+
RXOS_UTILS_SITE = $(BR2_EXTERNAL)/local/rxos-utils/src
RXOS_UTILS_SITE_METHOD = local

RXOS_UTILS_DEVNODES = $(call qstrip,$(BR2_RXOS_UTILS_STORAGE))
RXOS_UTILS_DEVNODES += $(call qstrip,$(BR2_RXOS_UTILS_DEVNODES))

RXOS_UTILS_STATUS_SED_CMDS += s|%LIBRARIAN_PORT%|$(call qstrip,$(BR2_LIBRARIAN_PORT))|;
RXOS_UTILS_STATUS_SED_CMDS += s|%STORAGE_DEVICE%|$(call qstrip,$(BR2_RXOS_UTILS_STORAGE))|;
RXOS_UTILS_STATUS_SED_CMDS += s|%PARTITIONS%|$(call qstrip,$(BR2_RXOS_UTILS_PARTITIONS))|;
RXOS_UTILS_STATUS_SED_CMDS += s|%IFACES%|$(foreach iface,$(call qstrip,$(BR2_RXOS_UTILS_IFACES)),\n$(iface))|;
RXOS_UTILS_STATUS_SED_CMDS += s|%PROCS%|$(foreach proc,$(call qstrip,$(BR2_RXOS_UTILS_PROCS)),\n$(proc))|;
RXOS_UTILS_STATUS_SED_CMDS += s|%HOSTS%|$(foreach host,$(call qstrip,$(BR2_RXOS_UTILS_HOSTS)),\n$(host))|;
RXOS_UTILS_STATUS_SED_CMDS += s|%DEVNODES%|$(foreach node,$(RXOS_UTILS_DEVNODES),\n$(node))|;
RXOS_UTILS_BOOTMODE_SED_CMDS += s|%BOOTDEV%|$(call qstrip,$(BR2_RXOS_UTILS_BOOTDEV))|;

define RXOS_UTILS_INSTALL_TARGET_CMDS
	$(SED) '$(RXOS_UTILS_STATUS_SED_CMDS)' $(@D)/status.sh
	$(SED) '$(RXOS_UTILS_BOOTMODE_SED_CMDS)' $(@D)/chbootfsmode.sh

	$(INSTALL) -dm0755 $(TARGET_DIR)/usr/share/cgi/
	$(INSTALL) -Dm644 $(@D)/common.sh $(TARGET_DIR)/usr/share/cgi/common.sh
	$(INSTALL) -Dm755 $(@D)/index.sh $(TARGET_DIR)/usr/share/cgi/index.sh
	$(INSTALL) -Dm755 $(@D)/check.sh $(TARGET_DIR)/usr/share/cgi/check
	$(INSTALL) -Dm755 $(@D)/top.sh $(TARGET_DIR)/usr/share/cgi/top
	$(INSTALL) -Dm755 $(@D)/net.sh $(TARGET_DIR)/usr/share/cgi/net
	$(INSTALL) -Dm755 $(@D)/mount.sh $(TARGET_DIR)/usr/share/cgi/mount

	$(INSTALL) -Dm755 $(@D)/status.sh $(TARGET_DIR)/usr/bin/status
	$(INSTALL) -Dm755 $(@D)/service.sh $(TARGET_DIR)/usr/sbin/service
	$(INSTALL) -Dm0755 $(@D)/chbootfsmode.sh \
		$(TARGET_DIR)/usr/sbin/chbootfsmode
endef

$(eval $(generic-package))
