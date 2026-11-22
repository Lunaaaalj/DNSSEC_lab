#!/usr/bin/env bash
# Start the 8 named instances. Run with sudo. BASE selects the tree (default /etc/bind/dns-lab).
set -eu
BASE=${BASE:-/etc/bind/dns-lab}
SERVERS=${SERVERS:-"root unsigned alpha signed beta gamma recursive1 recursive2"}
for s in $SERVERS; do
  named -4 -c "$BASE/$s/named.conf" && echo "started $s"
done
sleep 1; ss -ulnp | grep ':53 ' || true
