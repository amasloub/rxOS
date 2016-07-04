################################################################################
#
# sdr-config
#
################################################################################

SDR_CONFIG_VERSION = 1.0
SDR_CONFIG_LICENSE = GPLv3+
SDR_CONFIG_SITE = $(BR2_EXTERNAL)/local/sdr-config/src
SDR_CONFIG_SITE_METHOD = local

ifeq ($(BR2_PACKAGE_SDR_CONFIG),y)
PERSISTENT_CONF_LIST += /etc/conf.d/sdr
endif

define SDR_CONFIG_INSTALL_TARGET_CMDS
	$(INSTALL) -Dm644 $(@D)/sdr $(TARGET_DIR)/etc/conf.d/sdr
endef

define SDR_CONFIG_INSTALL_INIT_SYSV
	$(INSTALL) -Dm0755 $(BR2_EXTERNAL)/local/sdr-config/S80sdr \
		$(TARGET_DIR)/etc/init.d/S80sdr
endef

$(eval $(generic-package))
