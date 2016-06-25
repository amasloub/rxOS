#!/bin/sh
#
# Blink the LED in a loop at specified interval.
#
# This file is part of rxOS.
# rxOS is free sofware licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

# Adjust the interval for use with sleep command which uses seconds
INTERVAL="$(echo "$1" | awk '{print $1 / 1000}')"

. /usr/lib/led_ctrl.sh

while true; do
  led_on
  sleep "$INTERVAL"
  led_blank
  sleep "$INTERVAL"
done
