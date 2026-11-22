#!/usr/bin/env bash
# Reinstall the signed tree, restart all 8 servers and regenerate every piece of evidence.
# Run as a normal user (sudo is called only where needed; evidence files stay owned by you).
set -eu
D="$(cd "$(dirname "$0")" && pwd)"
sudo "$D/31-stop.sh" || true; sleep 1
sudo "$D/00-ips.sh" >/dev/null
sudo "$D/20-install.sh" 2>&1 | grep -E 'OK$|error|fail' || true
sudo "$D/30-start.sh" >/dev/null; sleep 1
"$D/40-tests.sh" 172.30.0.200 dnssec | tail -1
# fresh cache for the second resolver
sudo kill "$(cat /var/cache/bind/recursive1.pid)"; sleep 1
sudo SERVERS=recursive1 "$D/30-start.sh" >/dev/null
"$D/40-tests.sh" 172.30.0.100 sin_dnssec | tail -1
"$D/50-bogus.sh" | tail -12
