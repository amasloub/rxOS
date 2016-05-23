################################################################################
#
# nginx-config
#
################################################################################

NGINX_CONFIG_VERSION = 1.0
NGINX_CONFIG_LICENSE = GPL
NGINX_CONFIG_SITE = $(BR2_EXTERNAL)/local/nginx-config/src
NGINX_CONFIG_SITE_METHOD = local

define NGINX_CONFIG_INSTALL_TARGET_CMDS
	sed -i 's|%LIBRARIAN_PORT%|$(call qstrip,$(BR2_LIBRARIAN_PORT))|' \
		$(@D)/nginx.conf
	sed -i "s|%STYLE%|$$(cat $(@D)/style.css | sed ':a;N;$$!ba;s/\n/\\n/g')|" \
		$(@D)/*.html
	rm -f $(TARGET_DIR)/etc/nginx/*.default
	rm -f $(TARGET_DIR)/etc/nginx/*_params
	rm -f $(TARGET_DIR)/etc/nginx/fastcgi.conf
	rm -f $(TARGET_DIR)/usr/html/*.html
	$(INSTALL) -Dm644 $(@D)/nginx.conf $(TARGET_DIR)/etc/nginx/nginx.conf
	$(INSTALL) -Dm644 $(@D)/404.html $(TARGET_DIR)/usr/html/404.html
	$(INSTALL) -Dm644 $(@D)/502.html $(TARGET_DIR)/usr/html/502.html
	$(INSTALL) -Dm644 $(@D)/50x.html $(TARGET_DIR)/usr/html/50x.html
endef

$(eval $(generic-package))
