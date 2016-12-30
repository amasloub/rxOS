################################################################################
#
# bsdiff-aosp
#
################################################################################

BSDIFF_AOSP_VERSION = d355a6343e3e8739413af2724dac8c9a2aa6ddf1
BSDIFF_AOSP_SITE = $(call github,Outernet-Project,bsdiff-aosp,$(BSDIFF_AOSP_VERSION))
BSDIFF_AOSP_DEPENDENCIES = bzip2

define BSDIFF_AOSP_BUILD_CMDS
    $(TARGET_MAKE_ENV) $(MAKE) CXX=$(TARGET_CXX) -C $(@D) bspatch
endef

define BSDIFF_AOSP_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/bspatch $(TARGET_DIR)/usr/bin/bspatch
endef

$(eval $(generic-package))
