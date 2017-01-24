################################################################################
#
# ui2
#
################################################################################

UI2_VERSION = skylark-alpha-028

UI2_SITE = https://github.com/Outernet-Project/RxOS-UI2
UI2_SITE_METHOD = git

define UI2_INSTALL_TARGET_CMDS
    cp -dr --no-preserve=ownership $(@D)/target/* $(TARGET_DIR)
# clean up node_modules
    rm -rf $(TARGET_DIR)/usr/lib/node_modules/exif/test
endef

$(eval $(generic-package))
