#!/bin/sh
#
# Control the system status LED.
#
# This file is part of rxOS.
# rxOS is free sofware licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

BUS="%LED_BUS%"
CHIP="%LED_CHIP%"
ADDR="%LED_ADDR%"
I2C="i2cset -f -y $BUS $CHIP $ADDR"

kill_blink() {
  blink_pids="$(ps ax | grep '{blink}' | grep -v grep | awk '{print $1}')"
  kill -KILL $blink_pids
}

led_blank() {
  $I2C 0
}

led_off() {
  kill_blink
  led_blank
}

led_timer() {
  # Not available
  led_off
  led_on
}

led_mmc() {
  # Not available
  led_off
  led_on
}

led_on() {
  led_off
  $I2C 1
}

led_blink() {
  interval="$1"
  kill_blink
  blink "$interval" &
}

led_slow_blink() {
  led_blink "$SLOW_INTERVAL"
}

led_fast_blink() {
  led_blink "$FAST_INTERVAL"
}
