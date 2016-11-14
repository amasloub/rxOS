################################################################################
#
# ui2
#
################################################################################

UI2_VERSION = 0.45
UI2_SITE = https://github.com/Outernet-Project/RxOS-UI2
UI2_SITE_METHOD = git

ifeq ($(BR2_PACKAGE_UI2),y)
PERSISTENT_CONF_LIST += /etc/rxos_config.json
endif

define UI2_INSTALL_TARGET_CMDS
    cp -dr --no-preserve=ownership $(@D)/target/* $(TARGET_DIR)
# clean up node_modules
    rm -rf $(TARGET_DIR)/usr/lib/node_modules/exif/test
endef

$(eval $(generic-package))
