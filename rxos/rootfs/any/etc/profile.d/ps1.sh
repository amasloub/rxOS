#!/bin/sh
#
# Provide usable colorized PS1 prompt.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

if [ "$PS1" ]; then
  if [ "$(id -u)" -eq 0 ]; then
    export PS1='[Skylark]\[\033[31m\][\u@\h:\w]# \[\033[0m\]'
  else
    export PS1='[Skylark]\[\033[32m\][\u@\h:\w]$ \[\033[0m\]'
  fi
fi
