#!/bin/sh
#
# Create a HTML index of all CGI scripts.
#
# This file is part of rxOS.
# rxOS is free software licensed under the 
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

TITLE="rxOS diagnostics tools"

echo 'Content-Type: text/html'
echo 'Date: $(date -R)'
echo 'Last-Modified: $(date -R)'
echo

echo "<html>"
echo "<head><title>$TITLE</title></head>"
echo "<body>"
echo "<h1>$TITLE</h1>"
echo "<ul>"
for f in $(ls /usr/share/cgi | grep -v .sh); do
  echo "<li><a href=\"$f\">$f</a></li>"
done
echo "</ul>"
echo "</body>"
echo "</html>"
