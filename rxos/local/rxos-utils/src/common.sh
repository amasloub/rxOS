#!/bin/sh
#
# Common headers for CGI scripts
# 
# This file is part of rxOS.
# rxOS is free software licensed under the 
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

echo "Content-Type: text/plain"                                                                                                                                                 
echo "Date: $(date -R)"                                                                                                                                                         
echo "Last-Modified: $(date -R)"                                                                                                                                                
echo "Cache-Control: no-store"                                                                                                                                                  
echo
