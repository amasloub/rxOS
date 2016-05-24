#!/bin/sh
#
# Show status information about rxOS application and OS.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) Outernet Inc
# Some rights reserved.

LIBRARIAN_PORT="%LIBRARIAN_PORT%"

hdr() {
  msg="$1"
  printf "%-70s" "$msg"
}

pass() {
  printf "\e[32mPASS\e[0m\n"
}

fail() {
  printf "\e[31mFAIL\e[0m\n"
}

check_process() {
  name="$1"
  binary="$(which "$name")"
  hdr "Checking process $name: "
  if [ -z "$binary" ]; then
    fail
    return
  fi
  if ps ax | grep "$binary" | grep -v grep >/dev/null 2>&1; then
    pass
  else
    fail
  fi
}

check_net() {
  iface="$1"
  hdr "Checking interface $iface: "
  if ip link | grep "$iface" | grep "NO-CARRIER" >/dev/null 2>&1; then
    fail
  else
    pass
  fi
}

get_ip() {
  iface="$1"
  ipaddr=$(ip addr | grep -A1 "$iface" | grep "inet" \
    | awk '{print $2}' | cut -d/ -f1)
  hdr "Interface $iface IPv4 address: "
  if [ -z "$ipaddr" ]; then
    fail
  else
    echo "$ipaddr"
  fi
}

check_mount() {
  dev="$1"
  hdr "Checking mount for $dev: "
  if mount | egrep "^/dev/$dev" >/dev/null 2>&1; then
    pass
  else
    fail
  fi
}

check_devnode() {
  dev="$1"
  hdr "Checking device node /dev/$dev: "
  if [ -e "/dev/$dev" ]; then
    pass
  else
    fail
  fi
}

check_server() {
  msg="$1"
  url="$2"
  hdr "Checking $msg server: "
  if curl "$url" >/dev/null 2>&1; then
    pass
  else
    fail
  fi
}

check_process hostapd
check_process dnsmasq
check_process dropbear
check_process postgres
check_process lighttpd
check_process monitoring-client
check_process fsal-daemon
check_process librarian

check_net eth0
check_net wlan0

get_ip eth0
get_ip wlan0

check_devnode mmcblk0 
check_devnode dvb/adapeter0/frontend0

for part in 5 6 7 8; do
  check_mount "mmcblk0p$part"
done

check_server "Librarian HTTP" "http://127.0.0.1:$LIBRARIAN_PORT/"
check_server "nginx HTTP" "http://127.0.0.1/"
check_server "lftp FTP" "ftp://127.0.0.1/"

echo "Storage usage:"
df -h | tail -n+2 | awk '{printf "%-20s %5s %10s\n", $6, $5, $4}' \
  | egrep -v "^(/dev|/run)"
