################################################################################
#
# tweetnacl_tools
#
################################################################################

TWEETNACL_TOOLS_VERSION = 39d1077
TWEETNACL_TOOLS_SITE = https://github.com/Outernet-Project/tweetnacl-tools
TWEETNACL_TOOLS_SITE_METHOD = git
TWEETNACL_TOOLS_DEPENDENCIES = host-tweetnacl-tools

define TWEETNACL_TOOLS_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) CC=$(TARGET_CC) -C $(@D)
endef

define HOST_TWEETNACL_TOOLS_BUILD_CMDS
	$(HOST_MAKE_ENV) $(MAKE) -C $(@D)
endef


define TWEETNACL_TOOLS_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/tweetnacl-decrypt $(TARGET_DIR)/usr/bin/tweetnacl-decrypt
	$(INSTALL) -m 0755 -D $(@D)/tweetnacl-verify $(TARGET_DIR)/usr/bin/tweetnacl-verify
endef

define HOST_TWEETNACL_TOOLS_INSTALL_CMDS
	$(INSTALL) -m 0755 -D $(@D)/tweetnacl-decrypt $(HOST_DIR)/usr/bin/tweetnacl-decrypt
	$(INSTALL) -m 0755 -D $(@D)/tweetnacl-encrypt $(HOST_DIR)/usr/bin/tweetnacl-encrypt
	$(INSTALL) -m 0755 -D $(@D)/tweetnacl-keypair $(HOST_DIR)/usr/bin/tweetnacl-keypair
	$(INSTALL) -m 0755 -D $(@D)/tweetnacl-sigpair $(HOST_DIR)/usr/bin/tweetnacl-sigpair
	$(INSTALL) -m 0755 -D $(@D)/tweetnacl-sign $(HOST_DIR)/usr/bin/tweetnacl-sign
	$(INSTALL) -m 0755 -D $(@D)/tweetnacl-verify $(HOST_DIR)/usr/bin/tweetnacl-verify
endef

$(eval $(generic-package))
$(eval $(host-generic-package))

