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

LED="/sys/class/leds/led0"
LED_TRIGGER="$LED/trigger"
LED_BRIGHTNESS="$LED/brightness"
LED_DELAY_ON="$LED/delay_on"
LED_DELAY_OFF="$LED/delay_off"

SLOW_INTERVAL=500
FAST_INTERVAL=100

led_off() {
  echo none > "$LED_TRIGGER"
  echo 0 > "$LED_BRIGHTNESS"
}

led_timer() {
  echo timer > "$LED_TRIGGER"
}

led_mmc() {
  echo mmc0 > "$LED_TRIGGER"
}

led_on() {
  led_off
  echo none > "$LED_TRIGGER"
  echo 1 > "$LED_BRIGHTNESS"
}

led_blink() {
  interval="$1"
  led_timer
  echo "$inteval" > "$LED_DELAY_ON"
  echo "$interval" > "$LED_DELAY_OFF"
}

led_slow_blink() {
  led_blink $SLOW_INTERVAL
}

led_fast_blink() {
  led_blink $FAST_INTERVAL
}
