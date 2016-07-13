#!/bin/sh
#
# Show status information about rxOS application and OS.
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) Outernet Inc
# Some rights reserved.

LIBRARIAN_PORT="%LIBRARIAN_PORT%"
STORAGE_DEVICE="%STORAGE_DEVICE%"
PARTITIONS="%PARTITIONS%"
PROCS="%PROCS%"
IFACES="%IFACES%"
HOSTS="%HOSTS%"
DEVNODES="%DEVNODES%"
EXTRA_PATH="%PATH%"
VERBOSE=0
SUCCESS=0
COLOR=0

if [ -n "$EXTRA_PATH" ]; then
  export PATH="$EXTRA_PATH:$PATH"
fi

# Test book-keeping
TOTAL=0
FAILURES=0

report() {
  msg="$1"
  status="$2"
  TOTAL=$(( TOTAL + 1 ))
  if [ $SUCCESS -eq 0 ] && [ "$status" = pass ]; then
    return
  fi
  if [ $VERBOSE -eq 1 ]; then
    printf "%-50s %s\n" "${msg}:" "$status"
  else
    echo "[$status] $msg"
  fi
}

fail() {
  msg="$*"
  report "$msg" fail
  FAILURES=$(( FAILURES + 1 ))
}

pass() {
  msg="$*"
  report "$msg" pass
}

check_process() {
  name="$1"
  binary="$(which "$name")"
  hdr="Process $name"
  if [ -z "$binary" ]; then
    fail "$hdr"
    return
  fi
  if ps ax | grep "$binary" | grep -q -v grep; then
    pass "$hdr"
  else
    fail "$hdr"
  fi
}

check_net() {
  iface="$1"
  hdr="Interface $iface is up"
  if [ "$(cat "/sys/class/net/$iface/operstate")" = up ]; then
    pass "$hdr"
  else
    fail "$hdr"
  fi
}

get_ip() {
  iface="$1"
  ipaddr=$(ip addr | grep -A1 "$iface" | grep "inet" \
    | awk '{print $2}' | cut -d/ -f1)
  hdr="Interface $iface IPv4 address"
  if [ -z "$ipaddr" ]; then
    fail "$hdr"
  else
    pass "$hdr"
  fi
}

check_mount() {
  dev="$1"
  hdr="Mounted $dev"
  if mount | egrep -q "^(/dev/)?$dev"; then
    pass "$hdr"
  else
    fail "$hdr"
  fi
}

check_devnode() {
  dev="$1"
  hdr="Device node /dev/$dev exists"
  if [ -e "/dev/$dev" ]; then
    pass "$hdr"
  else
    fail "$hdr"
  fi
}

check_server() {
  msg="$1"
  proto="$2"
  port="$3"
  hdr="$msg server is responding"
  if curl --max-time 3 "$proto://localhost:$port/" >/dev/null 2>&1; then
    pass "$hdr"
  else
    fail "$hdr"
  fi
}

usage() {
  cat <<EOF
Usage: $0 [-hvsc]

Options:

    -h    show this message and exit
    -v    verbose output
    -s    report success not just failure
    -c    use colors


This program is part of rxOS.
rxOS is free software licensed under the
GNU GPL version 3 or any later version.

(c) Outernet Inc
Some rights reserved.
EOF
}

while getopts "hvsc" opt; do
  case "$opt" in
    h)
      usage
      exit 0
      ;;
    v)
      VERBOSE=1
      ;;
    s)
      SUCCESS=1
      ;;
    c)
      COLOR=1
      ;;
    *)
      echo "ERROR: invalid option '$opt'"
      usage
      exit 1
  esac
done

for proc in $PROCS; do
  check_process "$proc"
done

for iface in $IFACES; do
  check_net "$iface"
  get_ip "$iface"
done

for node in $DEVNODES; do
  check_devnode "$node"
done

for part in $PARTITIONS; do
  check_mount "${STORAGE_DEVICE}${part}"
done

for host in $HOSTS; do
  name="$(echo "$host" | cut -d: -f1)"
  proto="$(echo "$host" | cut -d: -f2)"
  port="$(echo "$host" | cut -d: -f3)"
  check_server "$name" "$proto" "$port"
done

if [ $FAILURES -gt 0 ]; then
  cat <<EOF

                   **********************************
                   ***** SOME TESTS HAVE FAILED *****
                   **********************************

NOTE:  Some items need more time to pass. For example, servers may need time
before they start responding. Other items may need manual intervention before
they become operational. When in doubt, rerun the tests after a short delay.

EOF
fi

echo
echo "Summary:"
echo "Tests run:     $TOTAL"
echo "Tests failed:  $FAILURES"

echo
echo "Storage usage:"
df -h | tail -n+2 | awk '{printf "%-20s %5s %10s\n", $6, $5, $4}' \
  | egrep -v "^(/dev|/run)"

echo
echo "Uptime:"
uptime
