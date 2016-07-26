################################################################################
#
# remote-support
#
################################################################################

REMOTE_SUPPORT_VERSION = 1.0
REMOTE_SUPPORT_LICENSE = GPL
REMOTE_SUPPORT_SITE = $(BR2_EXTERNAL)/local/remote-support/src
REMOTE_SUPPORT_SITE_METHOD = local

define REMOTE_SUPPORT_INSTALL_INIT_SYSV
	$(INSTALL) -Dm755 $(call lpkgdir,remote-support)/S11remotesetup \
		$(TARGET_DIR)/etc/init.d/S11remotesetup
	$(INSTALL) -Dm755 $(call lpkgdir,remote-support)/S99remote \
		$(TARGET_DIR)/etc/init.d/S99remote
endef

$(eval $(generic-package))
