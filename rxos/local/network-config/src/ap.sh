#!/bin/sh
#
# Start, stop, and restart hostapd
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

ACTION="$1"
PIDFILE="/var/run/hostapd.pid"
CONF="/etc/hostapd.conf"

start() {
  hostapd -B -P "$PIDFILE" "$CONF"
}

stop() {
  pid="$(cat "$PIDFILE")"
  [ -n "$pid" ] && kill "$pid"
}

restart() {
  stop
  sleep 2
  start
}

reload() {
  pid="$(cat "$PIDFILE")"
  [ -n "$pid" ] && kill -s SIGHUP "$pid"
}

help() {
  echo "Usage: $0 {start|stop|restart|reload}"
}

"${ACTION:=help}"
