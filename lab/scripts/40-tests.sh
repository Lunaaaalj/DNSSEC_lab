#!/usr/bin/env bash
# 40-tests.sh <recursive-ip> <label>   e.g.  sudo ./40-tests.sh 172.30.0.200 dnssec
# Captures port-53 traffic on lo and runs the dig battery; results in lab/evidence/.
set -u
R=${1:?resolver ip}; L=${2:?label}
OUT="$(cd "$(dirname "$0")/../evidence" && pwd)"
PCAP="$OUT/captura_recursivo_$L.pcapng"; LOG="$OUT/dig_$L.txt"
tshark -q -i lo -f "port 53" -w "$PCAP" 2>/dev/null & TP=$!
sleep 2; : > "$LOG"
q() { echo "### dig @$R $*" | tee -a "$LOG"; dig @"$R" "$@" +multi 2>&1 | tee -a "$LOG"; echo | tee -a "$LOG"; }
q www.beta.signed A +dnssec
q www.gamma.signed A +dnssec
q www.alpha.unsigned A +dnssec
q signed DNSKEY +dnssec
q beta.signed DS +dnssec
q nx.beta.signed A +dnssec
q gamma.signed DS +dnssec
sleep 2; kill $TP 2>/dev/null; wait $TP 2>/dev/null
echo "pcap: $PCAP ($(tshark -r "$PCAP" 2>/dev/null | wc -l) packets)"
