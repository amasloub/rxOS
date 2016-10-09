################################################################################
#
# incron-service
#
################################################################################

INCRONSERVICE_VERSION = 1.0
INCRONSERVICE_LICENSE = GPLv3+
INCRONSERVICE_SITE = $(BR2_EXTERNAL)/local/incron-service/src
INCRONSERVICE_SITE_METHOD = local


define INCRONSERVICE_INSTALL_INIT_SYSV
	$(INSTALL) -Dm0755 $(@D)/S99incrond   $(TARGET_DIR)/etc/init.d/S99incrond
endef

$(eval $(generic-package))
