#!/bin/sh
HELPTEXT="usage: wep_passphrase <ssid> <key1> [key2] [key3] [key4] [--index N]"

die() {
  echo >&2 "$@"
  exit 1
}

[ "$#" -lt 2 ] && die "$HELPTEXT"

SSID=$1
shift  # drop first argument out as it's assigned to ssid

# write static section start
cat << EOS
network={
	ssid="$SSID"
	key_mgmt=NONE
EOS

i=0
while test $# -gt 0
do
  arg="$1"
  if [ "$arg" = "--index" ]
  then
    # write active key index
    index="$2"
    echo "	wep_tx_keyidx=$index"
    # shift both parameter and argument out
    shift && shift
  else
    # disallow using more than 4 keys
    [ "$i" -gt 3 ] && break
    echo "	wep_key$i=\"$arg\""
    i=$((i+1))
    shift
  fi
done

# write closing brace
echo "}"
