################################################################################
#
# network-config
#
################################################################################

NETWORK_CONFIG_VERSION = 1.0
NETWORK_CONFIG_LICENSE = GPL
NETWORK_CONFIG_SITE = $(BR2_EXTERNAL)/local/network-config/src
NETWORK_CONFIG_SITE_METHOD = local

NETWORK_CONFIG_AP_IF = $(call qstrip,$(BR2_NETWORK_CONFIG_AP_IF))
NETWORK_CONFIG_AP_IP = $(call qstrip,$(BR2_NETWORK_CONFIG_AP_IP))
NETWORK_CONFIG_AP_NAME = $(call qstrip,$(BR2_NETWORK_CONFIG_AP_NAME))
NETWORK_CONFIG_DHCP_START = $(call qstrip,$(BR2_NETWORK_CONFIG_DHCP_START))
NETWORK_CONFIG_DHCP_END = $(call qstrip,$(BR2_NETWORK_CONFIG_DHCP_END))
NETWORK_CONFIG_DHCP_LDIR = $(call qstrip,$(BR2_NETWORK_CONFIG_DHCP_LDIR))
NETWORK_CONFIG_NETMASK = $(call qstrip,$(BR2_NETWORK_CONFIG_NETMASK))
NETWORK_CONFIG_TAG = $(call qstrip,$(BR2_NETWORK_CONFIG_TAG))

define NETWORK_CONFIG_INSTALL_TARGET_CMDS
	$(INSTALL) -Dm644 $(@D)/hostapd.conf $(TARGET_DIR)/etc/hostapd.conf
	$(INSTALL) -Dm644 $(@D)/dnsmasq.conf $(TARGET_DIR)/etc/dnsmasq.conf
	$(INSTALL) -Dm644 $(@D)/interfaces $(TARGET_DIR)/etc/network/interfaces.rxos
	$(INSTALL) -Dm755 $(@D)/ifplugd.action $(TARGET_DIR)/etc/ifplugd.action
	$(INSTALL) -Dm755 $(@D)/dhcpcfg $(TARGET_DIR)/sbin/dhcpcfg
	$(INSTALL) -Dm755 $(@D)/S81hostapd $(TARGET_DIR)/etc/init.d/S81hostapd
	
	sed -i 's|%IFACE%|$(NETWORK_CONFIG_AP_IF)|;s|%SSID%|$(NETWORK_CONFIG_AP_NAME)|;s|%IP%|$(NETWORK_CONFIG_AP_IP)|;s|%START%|$(NETWORK_CONFIG_DHCP_START)|;s|%END%|$(NETWORK_CONFIG_DHCP_END)|;s|%END%|$(NETWORK_CONFIG_DHCP_END)|;s|%LDIR%|$(NETWORK_CONFIG_DHCP_LDIR)|;s|%TAG%|$(NETWORK_CONFIG_TAG)|' \
		$(TARGET_DIR)/etc/network/interfaces.rxos \
		$(TARGET_DIR)/etc/hostapd.conf \
		$(TARGET_DIR)/etc/dnsmasq.conf
endef

$(eval $(generic-package))
