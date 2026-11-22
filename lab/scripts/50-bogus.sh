#!/usr/bin/env bash
# Bogus-data test: tamper with www.beta.signed WITHOUT re-signing, query both recursives, restore.
# Run as a normal user; sudo is used only for /etc/bind and named restarts.
set -u
Z=/etc/bind/dns-lab/beta/zones/db.beta.signed.signed
OUT="$(cd "$(dirname "$0")/../evidence" && pwd)"
LOG="$OUT/dig_bogus.txt"; PCAP="$OUT/captura_bogus.pcapng"
restart() {  # restart <servers...>  (clean caches / reload zone)
  for s in "$@"; do
    case $s in root) p=/run/named-root.pid;; *) p=/var/cache/bind/$s.pid;; esac
    sudo kill "$(cat $p)" 2>/dev/null
  done; sleep 1
  sudo SERVERS="$*" "$(dirname "$0")/30-start.sh" >/dev/null
}
sudo cp "$Z" "$Z.orig"
sudo sed -i -E 's/^(www\.beta\.signed\.[[:space:]]+[0-9]+[[:space:]]+IN[[:space:]]+A[[:space:]]+)172\.30\.0\.50/\1172.30.0.66/' "$Z"
sudo grep -E '^www\.beta\.signed\..*[[:space:]]A[[:space:]]' "$Z"
restart beta recursive1 recursive2
tshark -q -i lo -f "port 53" -w "$PCAP" 2>/dev/null & TP=$!
sleep 2; : > "$LOG"
q() { echo "### dig @$1 ${*:2}" | tee -a "$LOG"; dig @"$1" "${@:2}" +multi 2>&1 | tee -a "$LOG"; echo | tee -a "$LOG"; }
q 172.30.0.200 www.beta.signed A +dnssec          # validating: expect SERVFAIL + EDE bogus
q 172.30.0.200 www.beta.signed A +dnssec +cd      # checking disabled: forged data returned, no ad
q 172.30.0.100 www.beta.signed A +dnssec          # non-validating: forged data accepted
sleep 2; kill $TP 2>/dev/null; wait $TP 2>/dev/null
# restore
sudo mv "$Z.orig" "$Z"
restart beta recursive1 recursive2
echo "restored; sanity:"; dig @172.30.0.200 www.beta.signed A +dnssec | grep -E 'status|flags'
