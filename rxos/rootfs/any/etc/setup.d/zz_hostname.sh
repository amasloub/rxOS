#! /bin/sh

hostname=$(getconf netConf.hostname )

echo "$hostname" > /etc/hostname

hostname "$hostname"
