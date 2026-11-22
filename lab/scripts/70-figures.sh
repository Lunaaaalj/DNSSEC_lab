#!/usr/bin/env bash
# Regenerate the text evidence of the report figures and render each one to PNG with typst.
# Needs the lab running (delv) and the pcaps in lab/evidence. Run as a normal user from anywhere.
set -u
R="$(cd "$(dirname "$0")/../.." && pwd)"; E=$R/lab/evidence; V=$R/lab/v2; I=$R/docs/actividad3/img
cd "$R"
{ for z in ".:root/zones/db.root.signed" "signed:signed/zones/db.signed.signed" "beta.signed:beta/zones/db.beta.signed.signed" "gamma.signed:gamma/zones/db.gamma.signed"; do
    n=${z%%:*}; f=$V/${z#*:}
    echo "\$ named-checkzone $n ${f#$R/}"; named-checkzone "$n" "$f" 2>&1 | grep -v 'no addresses records'
  done
  for z in ".:root/zones/db.root.signed" "signed:signed/zones/db.signed.signed" "beta.signed:beta/zones/db.beta.signed.signed"; do
    n=${z%%:*}; f=$V/${z#*:}
    echo; echo "\$ dnssec-verify -o $n ${f#$R/}"; dnssec-verify -o "$n" "${f#$R/}" 2>&1
  done; } > "$E/fig_checkzone.txt"
{ echo "\$ tshark -r captura_recursivo_dnssec.pcapng -Y 'dns.flags.authenticated == 1'"
  tshark -r "$E/captura_recursivo_dnssec.pcapng" -Y 'dns.flags.authenticated == 1' 2>/dev/null | sed -E 's/Standard query response //' | cut -c1-120
  echo; echo "\$ tshark -r captura_recursivo_sin_dnssec.pcapng -Y 'dns.flags.authenticated == 1'"
  tshark -r "$E/captura_recursivo_sin_dnssec.pcapng" -Y 'dns.flags.authenticated == 1' 2>/dev/null
  echo "(no packets)"; } > "$E/fig_ad.txt"
{ for f in dnssec:200 sin_dnssec:100; do
    n=${f%%:*}; r=172.30.0.${f#*:}; flt="dns.qry.type == 48 && dns.flags.response == 0 && ip.dst != $r"
    echo "\$ tshark -r captura_recursivo_$n.pcapng -Y '$flt'"
    tshark -r "$E/captura_recursivo_$n.pcapng" -Y "$flt" 2>/dev/null; echo
  done; } > "$E/fig_dnskey.txt"
{ echo "\$ delv @172.30.0.200 -a lab/v2/anchor.conf.delv www.beta.signed A"
  delv @172.30.0.200 -a lab/v2/anchor.conf.delv www.beta.signed A 2>&1 | fold -s -w 100
  echo; echo "\$ delv @172.30.0.200 -a lab/v2/anchor.conf.delv www.gamma.signed A"
  delv @172.30.0.200 -a lab/v2/anchor.conf.delv www.gamma.signed A 2>&1 | fold -s -w 100; } > "$E/fig_delv.txt"
{ echo "\$ tshark -r captura_recursivo_dnssec.pcapng -Y 'dns.qry.type == 2 && dns.flags.response == 0 && ip.dst == 172.30.0.10'"
  tshark -r "$E/captura_recursivo_dnssec.pcapng" -Y 'dns.qry.type == 2 && dns.flags.response == 0 && ip.dst == 172.30.0.10' 2>/dev/null; echo
  echo "\$ tshark -r captura_recursivo_sin_dnssec.pcapng -Y 'dns.qry.type == 2 && dns.flags.response == 0 && ip.dst == 172.30.0.10'"
  tshark -r "$E/captura_recursivo_sin_dnssec.pcapng" -Y 'dns.qry.type == 2 && dns.flags.response == 0 && ip.dst == 172.30.0.10' 2>/dev/null; } > "$E/fig_ns.txt"
cat > "$I/term.typ" <<'T'
#let f = sys.inputs.f
#set page(width: auto, height: auto, margin: 10pt, fill: rgb("#101418"))
#set text(font: "DejaVu Sans Mono", size: 8pt, fill: rgb("#d8dee9"))
#raw(read(f), block: true)
T
for n in checkzone ad dnskey delv ns; do
  typst compile --root / --input f="$E/fig_$n.txt" --ppi 200 "$I/term.typ" "$I/fig_$n.png" 2>&1 | head -3
done
rm -f "$I/term.typ"; ls -l "$I"
