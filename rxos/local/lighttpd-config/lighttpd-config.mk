################################################################################
#
# lighttpd-config
#
################################################################################

LIGHTTPD_CONFIG_VERSION = 1.0
LIGHTTPD_CONFIG_LICENSE = GPL
LIGHTTPD_CONFIG_SITE = $(BR2_EXTERNAL)/local/lighttpd-config/src
LIGHTTPD_CONFIG_SITE_METHOD = local

LIGHTTPD_SED_CMDS += s|%LIBRARIAN_PORT%|$(call qstrip,$(BR2_LIBRARIAN_PORT))|g;
LIGHTTPD_SED_CMDS += s|%SERVER_ROOT%|$(call qstrip,$(BR2_LIGHTTPD_SERVER_ROOT))|g;
LIGHTTPD_SED_CMDS += s|%SERVER_TAG%|$(call qstrip,$(BR2_LIGHTTPD_SERVER_TAG))|g;
LIGHTTPD_SED_CMDS += s|%STATICDIR%|$(call qstrip,$(BR2_LIGHTTPD_STATICDIR))|g;
LIGHTTPD_SED_CMDS += s|%FAVICON%|$(call qstrip,$(BR2_LIGHTTPD_FAVICON))|g;
LIGHTTPD_SED_CMDS += s|%INTERNALDIR%|$(call qstrip,$(BR2_STORAGE_PRIMARY))|g;
LIGHTTPD_SED_CMDS += s|%EXTERNALDIR%|$(call qstrip,$(BR2_STORAGE_SECONDARY))|g;

LIGHTTPD_HTMLDIR = $(call qstrip,$(BR2_LIGHTTPD_SERVER_ROOT))

define LIGHTTPD_CONFIG_INSTALL_TARGET_CMDS
	$(SED) '$(LIGHTTPD_SED_CMDS)' $(@D)/lighttpd.conf
	$(SED) "s|%STYLE%|$$(cat $(@D)/style.css | sed ':a;N;$$!ba;s/\n/\\n/g')|" \
		$(@D)/*.html
	$(INSTALL) -Dm644 $(@D)/mime.conf $(TARGET_DIR)/etc/lighttpd/conf.d/mime.conf
	$(INSTALL) -Dm644 $(@D)/lighttpd.conf $(TARGET_DIR)/etc/lighttpd/lighttpd.conf
	$(INSTALL) -Dm644 $(@D)/modules.conf $(TARGET_DIR)/etc/lighttpd/modules.conf
	rm -rf $(TARGET_DIR)$(LIGHTTPD_HTMLDIR)/*
	$(INSTALL) -Dm644 $(@D)/404.html $(TARGET_DIR)$(LIGHTTPD_HTMLDIR)/404.html
	$(INSTALL) -Dm644 $(@D)/500.html $(TARGET_DIR)$(LIGHTTPD_HTMLDIR)/500.html
endef

$(eval $(generic-package))
