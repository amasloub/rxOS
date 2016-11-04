################################################################################
#
# ui2
#
################################################################################

UI2_VERSION = 0.28
UI2_SITE = https://github.com/Outernet-Project/RxOS-UI2
UI2_SITE_METHOD = git

define UI2_INSTALL_TARGET_CMDS
    cp -dr --no-preserve=ownership $(@D)/target/* $(TARGET_DIR)
endef

$(eval $(generic-package))
