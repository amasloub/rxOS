#!/bin/sh

LABEL_FILE="$(grep -l pcf8574a /sys/class/gpio/*/*label)"
BASE_FILE="$(dirname "$LABEL_FILE")/base"
BASE="$(cat "$BASE_FILE")"
GPIO_CLS="/sys/class/gpio"

# Pins
XIOP0=0
XIOP1=1
XIOP2=2
XIOP3=3
XIOP4=4
XIOP5=5
XIOP6=6
XIOP7=7
XIO_ALL="0 1 2 3 4 5 6 7"

get_pin() {
  pin="$1"
  echo "$GPIO_CLS/gpio$(( BASE + pin ))"
}

use() {
  pin="$1"
  echo "$(( BASE + pin ))" > "$GPIO_CLS/export" 
}

close() {
  pin="$1"
  echo "$(( BASE + pin ))" > "$GPIO_CLS/unexport"
}

use_all() {
  for pin in $XIO_ALL; do
    use "$pin"
  done
}

close_all() {
  for pin in $XIO_ALL; do
    close "$pin"
  done
}

read_pin() {
  pin="$1"
  property="$2"
  cat "$(get_pin "$pin")/$property"
}

gpio_test() {
  use_all
  echo "Reading value of XIO-P0: $(read_pin "$XIOP0" value)"
  echo "Reading value of XIO-P1: $(read_pin "$XIOP1" value)"
  echo "Reading value of XIO-P2: $(read_pin "$XIOP2" value)"
  echo "Reading value of XIO-P3: $(read_pin "$XIOP3" value)"
  echo "Reading value of XIO-P4: $(read_pin "$XIOP4" value)"
  echo "Reading value of XIO-P5: $(read_pin "$XIOP5" value)"
  echo "Reading value of XIO-P6: $(read_pin "$XIOP6" value)"
  echo "Reading value of XIO-P7: $(read_pin "$XIOP7" value)"
  close_all
}

[ "$(basename "$0")" = "gpio.sh" ] && gpio_test
