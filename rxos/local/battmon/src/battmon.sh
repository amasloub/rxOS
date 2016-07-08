#!/bin/sh
#
# Query battery charge information
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

BUS=0

ADC_CHIP=0x34
ADC_ADDR=0x82
ADC_ENABLE=0xC3

# ADC regisers
STATUS_REG=0x00
OPMODE_REG=0x01
BATTVMSB_REG=0x78
BATTVLSB_REG=0x79
BATTDSCGMSB_REG=0x7C
BATTDSCGLSB_REg=0x7D

SET="i2cset -y $BUS $ADC_ADDR"
GET="i2cget -y -f $BUS $ADC_ADDR"

# Enable ADC for battery voltage and current
adc_enable() {
  $SET $ADC_CHIP $ADC_ENABLE
}

# Get battery status (0 or 1)
# TODO: What does this do anyway?
batt_status() {
  pwr_status="$($GET $STATUS_REG)"
  echo $(( $(( pwr_status & 0x02 )) / 2 ))
}

# Whether battery is charging (0 or 1)
is_charging() {
  pwr_opmode="$($GET $OPMODE_REG)"
  echo $(( $(( pwr_opmode & 0x40 )) / 64 ))
}

# Whether battery is present (0 or 1)
has_batt() {
  pwr_opmode="$($GET $OPMODE_REG)"
  echo $(( $(( pwr_opmode & 0x20 )) / 32 ))
}

# The battery voltage (V)
batt_voltage() {
  v_msb="$($GET $BATTVMSB_REG)"
  v_lsb="$($GET $BATTVLSB_REG)"
  v_bin=$(( $(( v_msb << 4 )) | $(( $(( v_lsb & 0x0F )) )) ))
  echo "$v_bin * 1.1" | bc
}

# The battery discharge current (mA)
runtest() {

}


if [ "$_" = "$0" ]; then
  runtest
fi
