################################################################################
#
# cleanup-init
#
################################################################################

CLEANUP_VERSION = 1.0
CLEANUP_LICENSE = GPLv3+
CLEANUP_SITE = $(BR2_EXTERNAL)/local/cleanup/src
CLEANUP_SITE_METHOD = local

define CLEANUP_INSTALL_TARGET_CMDS
	$(INSTALL) -Dm755 $(@D)/cleanup.sh $(TARGET_DIR)/usr/sbin/cleanup
endef

define CLEANUP_INSTALL_INIT_SYSV
	$(INSTALL) -Dm755 $(call lpkgdir,cleanup)/S90cleanup \
		$(TARGET_DIR)/etc/init.d/S90cleanup
endef

$(eval $(generic-package))
