################################################################################
#
# rxos-utils
#
################################################################################

RXOS_UTILS_VERSION = 1.0
RXOS_UTILS_LICENSE = GPLv3+
RXOS_UTILS_SITE = $(BR2_EXTERNAL)/local/rxos-utils/src
RXOS_UTILS_SITE_METHOD = local

define RXOS_UTILS_INSTALL_TARGET_CMDS
	sed -i 's|%LIBRARIAN_PORT%|$(call qstrip,$(BR2_LIBRARIAN_PORT))|' \
		$(@D)/status.sh
	$(INSTALL) -Dm0755 $(@D)/service.sh $(TARGET_DIR)/usr/sbin/service
	$(INSTALL) -Dm0755 $(@D)/status.sh $(TARGET_DIR)/usr/bin/status
	$(INSTALL) -Dm0755 $(@D)/chbootfsmode.sh \
		$(TARGET_DIR)/usr/sbin/chbootfsmode
endef

$(eval $(generic-package))
