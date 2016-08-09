################################################################################
#
# ota-pkg
#
################################################################################

OTA_PKG_VERSION = 1.0
OTA_PKG_LICENSE = GPLv3+
OTA_PKG_SITE = $(BR2_EXTERNAL)/local/ota-pkg/src
OTA_PKG_SITE_METHOD = local

OTA_PKG_DTB_FILE = $(call qstrip,$(BR2_LINUX_KERNEL_INTREE_DTS_NAME)).dtb

OTA_PKG_SED_CMDS += s|%VERSION%|$(call qstrip,$(RXOS_VERSION))|;
OTA_PKG_SED_CMDS += s|%SUBPLATFORM%|$(call qstrip,$(RXOS_SUBPLATFORM))|;
OTA_PKG_SED_CMDS += s|%DTB%|$(OTA_PKG_DTB_FILE)|;
OTA_PKG_SED_CMDS += s|%IGNORE_VERSION%|$(BR2_OTA_PKG_VERSIONLESS)|;

ifeq ($(BR2_PACKAGE_OTA_PKG),y)
BR2_ROOTFS_POST_IMAGE_SCRIPT += $(OTA_PKG_SITE)/mkpkg.sh

ifneq ($(BR2_OTA_PKG_KEY),"")
define OTA_PKG_INSTALL_KEY_CMDS
$(INSTALL) -Dm644 $(call qstrip,$(BR2_OTA_PKG_KEY)) \
	$(BINARIES_DIR)/signature.pem
endef
endif # BR2_OTA_PKG_CERTIFICATE

endif # BR2_PACKAGE_OTA_PKG

ifneq ($(BR2_OTA_PKG_PREINSTALL),"")
define OTA_PKG_INSTALL_PRE_CMDS
$(INSTALL) -Dm644 $(call qstrp,$(BR2_OTA_PKG_PREINSTALL)) \
	$(BINARIES_DIR)/pre-install.sh
endef
endif

ifneq ($(BR2_OTA_PKG_POSTINSTALL),"")
define OTA_PKG_INSTALL_POST_CMDS
$(INSTALL) -Dm644 $(call qstrp,$(BR2_OTA_PKG_POSTINSTALL)) \
	$(BINARIES_DIR)/post-install.sh
endef
endif

define OTA_PKG_INSTALL_TARGET_CMDS
	$(SED) '$(OTA_PKG_SED_CMDS)' $(@D)/installer.in.sh
	$(INSTALL) -Dm755 $(@D)/installer.in.sh $(BINARIES_DIR)/installer.sh
	$(INSTALL) -Dm644 $(@D)/ca.crt $(TARGET_DIR)/etc/outernet/ca.crt
	$(OTA_PKG_INSTALL_KEY_CMDS)
	$(OTA_PKG_INSTALL_PRE_CMDS)
	$(OTA_PKG_INSTALL_POST_CMDS)
endef

$(eval $(generic-package))


show-sig:
	@echo $(BR2_OTA_PKG_KEY)
