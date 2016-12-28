################################################################################
#
# starsdr-arm
#
################################################################################

STARSDR_ARM_VERSION = 1.0
STARSDR_ARM_SITE = $(BR2_EXTERNAL)/local/starsdr-arm/src
STARSDR_ARM_SITE_METHOD = local

define STARSDR_ARM_INSTALL_TARGET_CMDS
    cp -dr --preserve=mode $(@D)/* $(TARGET_DIR)
endef

$(eval $(generic-package))
