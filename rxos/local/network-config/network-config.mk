################################################################################
#
# network-config
#
################################################################################

NETWORK_CONFIG_VERSION = 1.0
NETWORK_CONFIG_LICENSE = GPL
NETWORK_CONFIG_SITE = $(BR2_EXTERNAL)/local/network-config/src
NETWORK_CONFIG_SITE_METHOD = local

NETWORK_CONFIG_SUBS = s|%IFACE%|$(call qstrip,$(BR2_NETWORK_CONFIG_AP_IF))|;
NETWORK_CONFIG_SUBS += s|%SSID%|$(call qstrip,$(BR2_NETWORK_CONFIG_AP_NAME))|;
NETWORK_CONFIG_SUBS += s|%IP%|$(call qstrip,$(BR2_NETWORK_CONFIG_AP_IP))|;
NETWORK_CONFIG_SUBS += s|%START%|$(call qstrip,$(BR2_NETWORK_CONFIG_DHCP_START))|;
NETWORK_CONFIG_SUBS += s|%END%|$(call qstrip,$(BR2_NETWORK_CONFIG_DHCP_END))|;
NETWORK_CONFIG_SUBS += s|%END%|$(call qstrip,$(BR2_NETWORK_CONFIG_DHCP_END))|;
NETWORK_CONFIG_SUBS += s|%NETMASK%|$(call qstrip,$(BR2_NETWORK_CONFIG_NETMASK))|;
NETWORK_CONFIG_SUBS += s|%LDIR%|$(call qstrip,$(BR2_NETWORK_CONFIG_DHCP_LDIR))|;
NETWORK_CONFIG_SUBS += s|%TAG%|$(call qstrip,$(BR2_NETWORK_CONFIG_TAG))|

define NETWORK_CONFIG_INSTALL_TARGET_CMDS
	sed -i '$(NETWORK_CONFIG_SUBS)' $(@D)/interfaces $(@D)/hostapd.conf \
		$(@D)/dnsmasq.conf

	$(INSTALL) -Dm644 $(@D)/hostapd.conf $(TARGET_DIR)/etc/hostapd.conf
	$(INSTALL) -Dm644 $(@D)/dnsmasq.conf $(TARGET_DIR)/etc/dnsmasq.conf
	$(INSTALL) -Dm755 $(@D)/ifplugd.action $(TARGET_DIR)/etc/ifplugd.action
	$(INSTALL) -Dm755 $(@D)/dhcpcfg $(TARGET_DIR)/usr/sbin/dhcpcfg
	$(INSTALL) -Dm755 $(@D)/S81hostapd $(TARGET_DIR)/etc/init.d/S81hostapd
endef

$(eval $(generic-package))

# The interfaces file is installed by Buildroot's built-in target finalize 
# hook, so we need to override that with our own built-in hook.
define INSTALL_NETWORK_CONFIG_OVERRIDE
	$(INSTALL) -Dm644 $(NETWORK_CONFIG_DIR)/interfaces \
		$(TARGET_DIR)/etc/network/interfaces
endef

TARGET_FINALIZE_HOOKS += INSTALL_NETWORK_CONFIG_OVERRIDE
