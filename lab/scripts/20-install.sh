#!/usr/bin/env bash
# Copy lab/v2 to /etc/bind/dns-lab (without private keys) and check every config/zone. Run with sudo.
set -eu
SRC="$(cd "$(dirname "$0")/../v2" && pwd)"
DST=/etc/bind/dns-lab
mkdir -p "$DST"
rsync -a --delete --exclude 'keys/' --exclude '*.work' "$SRC/" "$DST/"
cd "$DST"
for s in root unsigned alpha signed beta gamma recursive1 recursive2; do
  named-checkconf "$s/named.conf" && echo "checkconf $s OK"
done
named-checkzone .               root/zones/db.root.signed
named-checkzone unsigned        unsigned/zones/db.unsigned
named-checkzone alpha.unsigned  alpha/zones/db.alpha.unsigned
named-checkzone signed          signed/zones/db.signed.signed
named-checkzone beta.signed     beta/zones/db.beta.signed.signed
named-checkzone gamma.signed    gamma/zones/db.gamma.signed
