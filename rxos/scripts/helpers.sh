#!/bin/bash

# This file contains helper functions used in post-build and post-image hooks.
#
#
# Copyright 2016 Outernet Inc
# Some rights reserved.
#
# Released under GPLv3. See COPYING file in the source tree.

norm='\e[0m'
wht='\e[1;37m'
blk='\e[0;30m'
blu='\e[0;34m'
lblu='\e[1;34m'
grn='\e[0;32m'
lgrn='\e[1;32m'
cya='\e[0;36m'
lcya='\e[1;36m'
red='\e[0;31m'
lred='\e[1;31m'
pur='\e[0;35m'
lpur='\e[1;35m'
ylw='\e[0;33m'
lylw='\e[1;33m'
gry='\e[0;30m'
lgry='\e[0;37m'

msg() {
  msg=$*
  echo -e "$grn====> $msg$norm"
}

submsg() {
  msg=$*
  echo -e "$ylw  >>> $msg$norm"
}

err() {
  msg=$*
  echo -e "$red********************************************************$norm"
  echo -e "$ylw$msg$norm"
  echo -e "$red********************************************************$norm"
}
