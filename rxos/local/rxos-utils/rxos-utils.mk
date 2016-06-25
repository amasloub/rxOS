################################################################################
#
# rxos-utils
#
################################################################################

RXOS_UTILS_VERSION = 1.0
RXOS_UTILS_LICENSE = GPLv3+
RXOS_UTILS_SITE = $(BR2_EXTERNAL)/local/rxos-utils/src
RXOS_UTILS_SITE_METHOD = local

RXOS_UTILS_STATUS_SED_CMDS += s|%LIBRARIAN_PORT%|$(call qstrip,$(BR2_LIBRARIAN_PORT))|;
RXOS_UTILS_STATUS_SED_CMDS += s|%STORAGE_DEVICE%|$(call qstrip,$(BR2_RXOS_UTILS_STORAGE))|;
RXOS_UTILS_STATUS_SED_CMDS += s|%PARTITIONS%|$(call qstrip,$(BR2_RXOS_UTILS_PARTITIONS))|;
RXOS_UTILS_BOOTMODE_SED_CMDS += s|%BOOTDEV%|$(call qstrip,$(BR2_RXOS_UTILS_BOOTDEV))|;

define RXOS_UTILS_INSTALL_TARGET_CMDS
	$(SED) '$(RXOS_UTILS_STATUS_SED_CMDS)' $(@D)/status.sh
	$(SED) '$(RXOS_UTILS_BOOTMODE_SED_CMDS)' $(@D)/chbootfsmode.sh
	$(INSTALL) -Dm0755 $(@D)/service.sh $(TARGET_DIR)/usr/sbin/service
	$(INSTALL) -Dm0755 $(@D)/status.sh $(TARGET_DIR)/usr/bin/status
	$(INSTALL) -Dm0755 $(@D)/chbootfsmode.sh \
		$(TARGET_DIR)/usr/sbin/chbootfsmode
endef

$(eval $(generic-package))
