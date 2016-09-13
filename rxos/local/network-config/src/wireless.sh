#!/bin/sh
#
# Activates the needed network configuration files and profiles before the
# network services are started.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.


AP_PROFILE="/etc/network/profiles.d/wlan0"
STA_PROFILE="/etc/network/profiles.d/wlan0-client"
WLAN_CFG="/etc/network/interfaces.d/wlan0"
DNSMASQ_AP="/etc/conf.d/dnsmasq/ap.conf"
DNSMASQ_STA="/etc/conf.d/dnsmasq/sta.conf"
DNSMASQ_CONF="/etc/dnsmasq.conf"
STA_MODE="STA"
AP_MODE="AP"


symlink() {
  target_cfg="$1"
  dest_path="$2"
  rm "$dest_path"
  ln -s "$target_cfg" "$dest_path"
}


activate_network_profile() {
  profile="$1"
  symlink "$profile" "$WLAN_CFG"
}


activate_dnsmasq_config() {
  config="$1"
  symlink "$config" "$DNSMASQ_CONF"
}


WIRELESS_MODE="$(cat /etc/conf.d/wireless 2>/dev/null)"

printf "Activating wireless configuration profile: "
if [ "$WIRELESS_MODE" = "$STA_MODE" ]; then
  echo "$STA_MODE"
  activate_network_profile "$STA_PROFILE"
  activate_dnsmasq_config "$DNSMASQ_STA"
else
  echo "$AP_MODE"
  activate_network_profile "$AP_PROFILE"
  activate_dnsmasq_config "$DNSMASQ_AP"
fi
