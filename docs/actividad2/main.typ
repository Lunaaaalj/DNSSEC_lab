// ============================================================
//  Technical report — Part 2 (draft)
//  arXiv-style template + DNS/BIND/DNSSEC lab content
// ============================================================

#let arxiv(
  title: [],
  authors: (),
  abstract: none,
  keywords: (),
  professors: none,
  date: "",
  body,
) = {
  set document(title: title, author: authors.map(a => a.name))
  set page(paper: "us-letter", margin: (x: 1.1in, y: 1in), numbering: "1", number-align: center)
  set text(font: "New Computer Modern", size: 11pt, lang: "en")
  set par(justify: true, leading: 0.62em, spacing: 0.9em)

  set heading(numbering: "1.1")
  show heading: it => { v(1.1em, weak: true); it; v(0.6em, weak: true) }
  show heading.where(level: 1): set text(size: 13pt, weight: "bold")
  show heading.where(level: 2): set text(size: 11.5pt, weight: "bold")
  show heading.where(level: 3): set text(size: 11pt, weight: "bold", style: "italic")

  set math.equation(numbering: "(1)")
  show link: set text(fill: rgb("#1a4fa0"))
  show ref: set text(fill: rgb("#1a4fa0"))
  show figure.caption: set text(size: 10pt)
  show raw: set text(size: 9pt)
  show raw.where(block: true): it => block(
    width: 100%, fill: luma(246), stroke: 0.4pt + luma(210), inset: 7pt, radius: 2pt, breakable: true, it,
  )
  set enum(indent: 1em)
  set list(indent: 1em)

  align(center)[
    #v(0.5em)
    #text(size: 17pt, weight: "bold")[#title]
    #v(1.2em)
    #grid(
      columns: calc.min(authors.len(), 3) * (1fr,),
      gutter: 1.2em,
      ..authors.map(a => [
        #text(size: 12pt)[*#a.name*] \
        #text(size: 10pt)[#a.at("affiliation", default: "")]
      ]),
    )
    #if professors != none [
      #v(0.6em)
      #text(size: 10pt)[Professor: #professors]
    ]
    #v(0.8em)
    #text(size: 10pt)[#date]
    #v(1em)
  ]

  if abstract != none {
    pad(x: 2.2em)[
      #align(center)[#text(weight: "bold")[Abstract]]
      #v(0.3em)
      #abstract
      #if keywords.len() > 0 [
        #v(0.4em)
        *Keywords:* #keywords.join(", ")
      ]
    ]
    v(1em)
  }
  body
}

// ---------- Draft utilities ----------
#let todo(x) = text(fill: rgb("#b00020"))[\[*TODO:* #x\]]
#let evidencia(desc, cap) = figure(
  rect(width: 100%, height: 2.6cm, stroke: (dash: "dashed", paint: gray), radius: 2pt)[
    #align(center + horizon)[#text(fill: gray, size: 9.5pt)[Insert screenshot: #desc]]
  ],
  caption: cap,
)
#let tabla(align: left + horizon, ..args) = {
  set text(size: 9pt)
  set par(justify: false)
  table(
    stroke: none,
    align: align,
    inset: (x: 5pt, y: 4pt),
    table.hline(),
    ..args,
    table.hline(),
  )
}
#let hd(x) = text(weight: "bold")[#x]
#show figure.where(kind: table): set figure.caption(position: top)
#let captura(path, cap, lbl, w: 85%) = [#figure(image(path, width: w), caption: cap)#label(lbl)]
#let professor = [Mohd Anas Wajid]
// ============================================================
#show: arxiv.with(
  title: [DNS Infrastructure with BIND and DNSSEC Analysis \ #text(size: 13pt, weight: "regular")[Technical report, part 2 (draft)]],
  authors: (
    (name: "Montserrat Rodríguez Ramírez", affiliation: "A01661271"),
    (name: "Jannette Cristina Flores Rodríguez", affiliation: "A0012345"),
    (name: "Angel Eduardo Luna", affiliation: "Tecnológico de Monterrey, Campus Monterrey"),
    (name: "Carolina Sarahí Sánchez Meneses", affiliation: "A00227980"),
    (name: "Elías Alejandro Corral Rodríguez", affiliation: "A01743624"),
  ),

  professors: professor,
  date: "November 16, 2026",
  abstract: [
    This report documents the setup of a laboratory DNS tree (root, the `unsigned` TLD, the `alpha.unsigned`
    zone and a recursive resolver) using BIND 9.20.30 on loopback interfaces in Kali Linux, its verification
    with `named-checkconf` and `named-checkzone`, and the analysis of DNS traffic with TShark and a Python
    script that extracts SOA, NS and A records together with their TTL. DNSSEC records of the `starcke.mx`
    domain are then queried through the public resolver 8.8.8.8 and through the local resolver, and the
    results are compared. Finally, the BIND tools for signing zones with DNSSEC are reviewed.
  ],
  keywords: ("DNS", "BIND 9.20", "DNSSEC", "TTL", "TShark", "SOA"),
)

= Laboratory Setup

== Environment and addressing

The laboratory was implemented in a virtual machine running Kali Linux (arm64), using the loopback option
allowed by the instructions: each DNS server listens on a different IPv4 address bound to the `lo`
interface, so that four independent `named` instances coexist on the same host. BIND 9.20.30 was installed.

#figure(
  tabla(
    columns: (auto, auto, auto, 1fr),
    hd[Server], hd[Address], hd[Role], hd[Zone / function],
    [Root], [`172.30.0.10`], [Authoritative], [Zone `.`; delegates `unsigned.` to `ns.unsigned.`],
    [Unsigned], [`172.30.0.20`], [Authoritative (gTLD)], [Zone `unsigned.`; delegates `alpha.unsigned.`],
    [Alpha], [`172.30.0.30`], [Authoritative], [Zone `alpha.unsigned.`; contains `www`],
    [Recursive1], [`172.30.0.100`], [Recursive], [Resolves from the private root (_root hints_)],
  ),
  caption: [Laboratory servers.],
) <tab:servidores>

The addresses were assigned to the `lo` interface with `sudo ip addr add 172.30.0.10/32 dev lo` (and likewise for `.20`, `.30` and `.100`), as shown in @fig:loopback. The installed version, BIND 9.20.30, was verified with `named -v` (@fig:bind-version).

#captura("01_Instalacion_BIND_version.png", [BIND 9.20.30 installation on Kali Linux and version check with `named -v`.], "fig:bind-version")
#captura("02_IPs_loopback.png", [IPv4 addresses assigned to the `lo` interface for the four servers.], "fig:loopback")

== File structure

The structure follows the one requested by the challenge instructor:

```
.
├── alpha
│   ├── named.conf
│   └── zones/db.alpha.unsigned
├── recursive1
│   ├── named.conf
│   └── zones/db.root.hints
├── root
│   ├── named.conf
│   └── zones/db.root
└── unsigned
    ├── named.conf
    └── zones/db.unsigned
```

== Server configuration

The parameters of each `named.conf` follow the instructor's guidelines (no recursion on the authoritative
servers, `allow-query { any; }`, and recursion restricted to `172.30.0.0/24` on the recursive server). The
configuration of the `alpha` server, which was designed by the team, is shown below.

```
// alpha/named.conf
options {
    directory "/var/cache/bind";
    listen-on { 172.30.0.30; };
    listen-on-v6 { none; };
    recursion no;
    allow-query { any; };
};

zone "alpha.unsigned" {
    type primary;
    file "/var/lib/bind/db.alpha.unsigned";
};
```

The zone includes the `A` record for `www` inside the same zone file, as the activity requires. The SOA and NS
values match those observed later in the capture (@tab:registros):

```
; alpha/zones/db.alpha.unsigned
$TTL 86400
@   IN SOA ns.alpha.unsigned. admin.alpha.unsigned. (
        2026111601 ; serial (YYYYMMDDnn)
        3600       ; refresh
        900        ; retry
        604800     ; expire
        86400 )    ; minimum (negative TTL)

@       IN NS  ns.alpha.unsigned.
ns      IN A   172.30.0.30
www     IN A   172.30.0.30
```

The consistency of the tree depends on the delegations: the root delegates `unsigned.` (`NS ns.unsigned.` with
glue `172.30.0.20`) and `unsigned` delegates `alpha.unsigned.` (`NS ns.alpha.unsigned.` with glue
`172.30.0.30`). Both delegations were confirmed in the captured traffic (packets 2 and 4).


== Verification with `named-checkconf` and `named-checkzone`

Each level of the tree was verified. With `named-checkconf`, no output indicates a valid configuration; with
`named-checkzone`, the expected result is `OK`.

```bash
named-checkconf root/named.conf
named-checkconf unsigned/named.conf
named-checkconf alpha/named.conf
named-checkconf recursive1/named.conf

named-checkzone .               root/zones/db.root
named-checkzone unsigned        unsigned/zones/db.unsigned
named-checkzone alpha.unsigned  alpha/zones/db.alpha.unsigned
```

No messages were produced by `named-checkconf` at any of the four levels, and `named-checkzone` ended with `OK` for the three zones (@fig:check-root, @fig:check-unsigned, @fig:check-alpha and @fig:check-recursive); all three zones load with serial `2026111601`. A warning (_has no addresses records_) appears for `ns.unsigned` in `root` and for `ns.alpha.unsigned` in `unsigned`. It is a warning, not an error, and the instructions state that `OK` is the expected result regardless of warnings. The `-D` dump of the root zone shows the `A` record of `ns.unsigned`, and the queries of the next section confirm that both delegations return their glue records (fig:dig-root and fig:dig-unsigned).

#captura("03_Root_validacion_delegacion.png", [Verification of the `root` server, with a dump of the root zone (`-D`).], "fig:check-root")
#captura("04_Unsigned_validacion.png", [Verification of the `unsigned` server.], "fig:check-unsigned")
#captura("05_Alpha_registro_A_y_validacion.png", [Verification of the `alpha` server and its `A` record for `www`.], "fig:check-alpha")
#captura("06_Recursivo_root_hints.png", [Verification of the recursive server and contents of `db.root.hints`.], "fig:check-recursive")

= Tests with `dig` and Traffic Capture

== Methodology

Traffic was captured on the `lo` interface, filtering port 53. Because of problems with Wireshark's graphical
interface, TShark (Dumpcap 4.6.6) was used. Queries were issued with `dig` to each server in the tree and to the
recursive server, and the resulting trace (`captura_dns.pcapng`, 12 packets) was processed with the script
`analizar_dns.py` (appendix), which calls `tshark` with the filter `dns.flags.response == 1` and exports the
packet number, query, record name, type and TTL to `registros_dns.csv`.

````bash
sudo tshark -i lo -f "port 53" -w ~/captura_dns.pcapng
dig @172.30.0.10  unsigned. NS +norecurse
dig @172.30.0.20  alpha.unsigned. NS +norecurse
dig @172.30.0.30  alpha.unsigned. SOA +norecurse
dig @172.30.0.30  alpha.unsigned. NS +norecurse
dig @172.30.0.30  www.alpha.unsigned. A +norecurse
dig @172.30.0.100 www.alpha.unsigned. A
````


The authoritative servers were queried with `+norecurse` (`RD=0` in the queries of packets 1 to 9), while the query to the recursive server (packet 11) carries `RD=1`. Because of the loopback setup, the `dig` client and the queried server reside on the same host, so in the trace the source and destination addresses of each packet coincide with that of the queried server. @fig:dig-root, @fig:dig-unsigned and @fig:dig-alpha show the responses of the root, `unsigned` and `alpha` servers; these screenshots come from an earlier run than the capture (same data, different message IDs and timestamps).

#captura("07_Root_delegacion_a_unsigned.png", [Query to the root server: delegation of `unsigned` with glue record.], "fig:dig-root")
#captura("08_Unsigned_delegacion_a_alpha.png", [Query to `unsigned`: delegation of `alpha.unsigned` with glue record.], "fig:dig-unsigned")
#captura("09_Alpha_respuesta_A_autoritativa.png", [Authoritative answer (`aa`) from `alpha` for `www.alpha.unsigned`.], "fig:dig-alpha")


== Extracted records

The script extracted 13 records. @tab:registros lists them, adding the DNS message section and the authority
flag (`AA`), which were obtained by decoding the same capture; the original CSV does not include these two
columns.

#figure(
  tabla(
    columns: (auto, auto, auto, auto, auto, auto, 1fr),
    hd[Pkt], hd[Server], hd[Record], hd[Type], hd[TTL (s)], hd[Section], hd[Data / remark],
    [2],  [Root `.10`],   [`unsigned`],            [NS],  [86400], [Authority], [`ns.unsigned`, `AA=0` (referral)],
    [2],  [Root `.10`],   [`ns.unsigned`],         [A],   [86400], [Additional], [`172.30.0.20` (glue)],
    [4],  [Unsigned `.20`], [`alpha.unsigned`],    [NS],  [86400], [Authority], [`ns.alpha.unsigned`, `AA=0` (referral)],
    [4],  [Unsigned `.20`], [`ns.alpha.unsigned`], [A],   [86400], [Additional], [`172.30.0.30` (glue)],
    [6],  [Alpha `.30`],  [`alpha.unsigned`],      [SOA], [86400], [Answer], [`AA=1`; see @tab:soa],
    [6],  [Alpha `.30`],  [`alpha.unsigned`],      [NS],  [86400], [Authority], [`ns.alpha.unsigned`],
    [6],  [Alpha `.30`],  [`ns.alpha.unsigned`],   [A],   [86400], [Additional], [`172.30.0.30`],
    [8],  [Alpha `.30`],  [`alpha.unsigned`],      [NS],  [86400], [Answer], [`AA=1`],
    [8],  [Alpha `.30`],  [`ns.alpha.unsigned`],   [A],   [86400], [Additional], [`172.30.0.30`],
    [10], [Alpha `.30`],  [`www.alpha.unsigned`],  [A],   [86400], [Answer], [`172.30.0.30`, `AA=1`],
    [10], [Alpha `.30`],  [`alpha.unsigned`],      [NS],  [86400], [Authority], [`ns.alpha.unsigned`],
    [10], [Alpha `.30`],  [`ns.alpha.unsigned`],   [A],   [86400], [Additional], [`172.30.0.30`],
    [12], [Recursive `.100`], [`www.alpha.unsigned`], [A], [*83425*], [Answer], [`172.30.0.30`, `AA=0`, `RA=1`],
  ),
  caption: [Records extracted from `captura_dns.pcapng`.],
) <tab:registros>

The TTLs of packets 2 through 10 (86400 s) match the `$TTL 86400` configured in each zone, so they are
consistent with the configuration. The referral responses from the root and from `unsigned` carry `AA=0`
because those servers are not authoritative for the queried name but delegate it; only `alpha` answers with
`AA=1`.

== SOA parameters

@tab:soa compares the SOA of `alpha.unsigned` (packet 6) with the references in the literature: RFC 1912
@rfc1912 (refresh from 1200 to 43200 s; expire from 2 to 4 weeks) and RIPE-203 @ripe203 (86400, 7200, 3600000
and 172800 s).

#figure(
  tabla(
    columns: (0.9fr, 1.5fr, 1.9fr, 1.7fr),
    align: (left + horizon),
    hd[Field], hd[Measured value], hd[Reference], hd[Comment],
    [MNAME], [`ns.alpha.unsigned.`], [—], [Consistent with the zone's NS],
    [RNAME], [`admin.alpha.unsigned.`], [—], [Administrator contact],
    [Serial], [2026111601], [YYYYMMDDnn], [Recommended format],
    [Refresh], [3600 s], [1200–43200 (RFC 1912); 86400 (RIPE-203)], [Within the RFC 1912 range],
    [Retry], [900 s], [7200 (RIPE-203)], [Shorter than refresh; more aggressive than RIPE-203],
    [Expire], [604800 s (7 d)], [1209600–2419200 (RFC 1912); 3600000 (RIPE-203)], [Below both references],
    [Minimum], [86400 s], [172800 (RIPE-203)], [Negative-caching TTL],
  ),
  caption: [SOA of `alpha.unsigned` against recommended values.],
) <tab:soa>

The SOA matches that of the rest of the tree (the root SOA observed in packet 32 of the second capture is
identical except for the names). The _expire_ value of 7 days is lower than the one recommended in the
literature, which is acceptable in a laboratory with a single server per zone, but it should be justified in
the report.


== TTL on the recursive server

The first query for `www.alpha.unsigned` to the recursive server (@fig:recursive, 12:12:39) returned the full TTL, 86400 s, because the server resolved the name from the private root and cached the answer. When the query was repeated during the capture (packet 12 of @tab:registros, 13:02:14), the TTL was 83425 s. The difference, 2975 s (49 min 35 s), matches the time elapsed between both queries: the recursive server did not query the authoritative servers again (there is no traffic toward them between packets 11 and 12) and answered from its cache, with `RA=1` and `AA=0`, returning the remaining TTL.

#captura("10_Recursivo_resuelve_www_alpha.png", [Query to the recursive server `172.30.0.100` (12:12:39): TTL 86400 s.], "fig:recursive")

= DNSSEC Analysis with `starcke.mx`

== Procedure

This part is outside the local laboratory. `starcke.mx` was queried through the public resolver 8.8.8.8 and,
for comparison, through the local recursive server `172.30.0.100`:

```bash
# 13:06, over UDP
dig @8.8.8.8 starcke.mx DNSKEY +dnssec
dig @8.8.8.8 starcke.mx DS +dnssec
dig @8.8.8.8 starcke.mx SOA +dnssec
# 13:09, over TCP
dig @8.8.8.8 starcke.mx. NS +dnssec +tcp +time=5      # also A, AAAA and RRSIG
dig @8.8.8.8 noexiste-20261116.starcke.mx. A +dnssec +tcp +time=5
# Local recursive server (no validation)
dig @172.30.0.100 starcke.mx. A +dnssec
# 13:11, with capture
sudo tshark -i any -f "port 53" -a duration:25 -w /tmp/captura_dnssec.pcapng
dig @8.8.8.8 starcke.mx. A +dnssec +edns=0 +bufsize=1232 +tcp     # also the non-existent name
```

The first queries (DNSKEY, DS and SOA) were sent over UDP; the rest (NS, A, AAAA, RRSIG and a non-existent name) were repeated with `+tcp`. The traffic was captured with TShark on the `any` interface for 25 seconds (@fig:tshark), unlike the first capture, which used `lo`. The trace `captura_dnssec.pcapng` (82 packets) contains three transactions with 8.8.8.8, all over TCP, and one with the local recursive server.


#captura("17_TShark_trafico_DNSSEC_guardado.png", [DNSSEC traffic capture with TShark and last queries (`+edns=0 +bufsize=1232 +tcp`).], "fig:tshark")

== Results with 8.8.8.8

#figure(
  tabla(
    columns: (auto, 1fr, auto, auto, auto),
    hd[Record], hd[Content], hd[TTL (s)], hd[TTL in capture (s)], hd[Source],
    [SOA], [`ns1.teuto.net. hostmaster.teuto.net. 2026111502 28000 7200 604800 86400`], [7200], [7078 (pkt. 26)], [@fig:g-dnskey],
    [NS], [`ns1.teuto.net.`, `ns2.teuto.net.`, `ns3.teuto.net.` (glue A: `212.15.202.2`, `212.15.202.3`, `212.15.205.12`, TTL 106 to 108 s)], [7200], [—], [@fig:g-ns],
    [A], [`212.8.207.35`], [7200], [7077 (pkt. 16)], [@fig:g-ns],
    [AAAA], [`2001:ae2:207::1:eb:2`], [7200], [—], [@fig:g-ns],
    [DNSKEY], [Two keys, algorithm 13 (ECDSAP256SHA256): KSK (flags 257) and ZSK (flags 256)], [7200], [6884 (pkt. 6)], [@fig:g-dnskey],
    [DS], [`25609 13 2 7888AD62…` (SHA-256)], [86400], [—], [@fig:g-dnskey],
    [RRSIG], [Did not appear], [—], [—], [fig:nsec],
    [NSEC/NSEC3], [Did not appear (the non-existent name returned only the SOA)], [—], [—], [fig:nsec],
  ),
  caption: [Records obtained for `starcke.mx` via 8.8.8.8.],
) <tab:dnssec>

When queried directly (@fig:g-dnskey and @fig:g-ns), 8.8.8.8 returned 7200 s for every record of the `starcke.mx` zone (SOA, NS, A, AAAA and DNSKEY), which indicates that the TTL configured in the zone is 7200 s. The `DS` record has a TTL of 86400 s because it is published by the parent zone (`.mx`), which sets that value. The TTLs in the capture (6884, 7077 and 7078 s) are remaining values in Google's cache: they equal 7200 s minus the time elapsed since the initial query (316 s, 123 s and 122 s, respectively).

#captura("13_Google_DNSKEY_DS_SOA.png", [DNSKEY, DS and SOA of `starcke.mx` via 8.8.8.8.], "fig:g-dnskey")
#captura("14_Google_NS_A_AAAA.png", [NS, A and AAAA of `starcke.mx` via 8.8.8.8 (TCP).], "fig:g-ns")

== Comparison with the local recursive server

For the local recursive server, the query `starcke.mx A` returns `NXDOMAIN` with `RA=1` and `AD=0` (packet 32).
The authority section contains the SOA of the private root (`ns.root. admin.root. 2026111601 3600 900 604800
86400`) with a TTL of 10492 s, which is the remaining negative TTL in cache. This is expected: the recursive
server only knows the laboratory root, which does not delegate the `mx` TLD, so it cannot resolve Internet names.
In addition, validation was disabled (`dnssec-validation no`), so it will never set `AD`.

#figure(
  tabla(
    columns: (auto, 1fr, 1fr),
    hd[Aspect], hd[8.8.8.8], hd[Local recursive `172.30.0.100`],
    [Result of `starcke.mx A`], [`NOERROR`, `212.8.207.35`], [`NXDOMAIN`],
    [Source of authority], [Public DNS (real root, `.mx`, `starcke.mx`)], [Laboratory private root],
    [SOA returned], [`ns1.teuto.net.` (zone `starcke.mx`)], [`ns.root.` (private zone `.`)],
    [DNSSEC validation], [Supported by the service], [Disabled (`dnssec-validation no`)],
    [Chain of trust], [Real root → `mx` → `starcke.mx`], [Does not exist],
  ),
  caption: [Differences between the two resolvers.],
) <tab:comparacion>

The negative TTL of the private root's SOA was 10800 s on the first query (@fig:local, 13:06:37) and then decreased (10606 s at 13:09:51 and 10492 s at 13:11:45, see @fig:nsec and @fig:tshark). It is lower than the `minimum` of the SOA (86400 s) because BIND limits negative caching by default to three hours (`max-ncache-ttl`, 10800 s). Another difference is that the response of the local server does return the `DO` flag in the `OPT` pseudo-record, even though it does not validate (`AD=0`) because of `dnssec-validation no`, whereas the responses from 8.8.8.8 do not.

#captura("15_Comparacion_recursivo_local_NXDOMAIN.png", [Query for `starcke.mx` to the local recursive server: `NXDOMAIN`.], "fig:local")

== Absence of RRSIG and NSEC/NSEC3

The zone does publish DNSSEC keys (there is a DNSKEY with algorithm 13), so `RRSIG` records were expected in the
responses. The trace shows that the queries to 8.8.8.8 carry the `DO` bit (EDNS, flag `0x8000`), but the
responses contain no `RRSIG`, the response `OPT` does not return `DO`, and `AD=0`. The query for a non-existent
name (`noexiste-20261116.starcke.mx`) returned only the SOA, with no `NSEC`/`NSEC3`.

There is also background traffic toward real root servers from `192.168.64.2`, and the responses to those queries
carry `RA=1` (root servers do not offer recursion) and TTLs that decrease consistently across different
addresses (root DNSKEY: 89993 s and 89986 s, 7 s apart). This suggests that some network element (for example,
the VM's NAT or a transparent DNS proxy) intercepts DNS traffic and answers from its own cache, stripping the
DNSSEC data.

This explanation is a hypothesis, not a conclusion. To confirm it:

```bash
dig @8.8.8.8 +dnssec +multi +tcp starcke.mx DNSKEY       # do RRSIGs and the ad flag arrive?
dig @8.8.8.8 +dnssec +cd starcke.mx A
dig @1.1.1.1 +dnssec starcke.mx A                        # another resolver
dig @9.9.9.9 +dnssec noexiste-xyz.starcke.mx A           # look for NSEC3 in the authority section
dig @8.8.8.8 +dnssec . DNSKEY                            # ad flag on a signed zone?
kdig @8.8.8.8 +tls +dnssec starcke.mx DNSKEY             # DNS over TLS, avoids interception on port 53
```


#captura("16_Prueba_inexistencia_NSEC_no_observado.png", [RRSIG query and non-existent name query via 8.8.8.8: no RRSIG or NSEC/NSEC3 records are returned.], "fig:nsec")

The RRSIG query and the non-existent-name query are shown in @fig:nsec.

It is also possible that part of that background traffic is generated by the laboratory's own `named` instances (root-key priming and managed-keys refresh), which should be ruled out before attributing it to the network.

= BIND Tools for DNSSEC Signing

BIND 9.20 offers two approaches. The first is automatic signing with `dnssec-policy`, which since 9.20 is the
only option for signing managed by `named`, because `auto-dnssec` was removed @bind920notes. In 9.20, zones
configured with `dnssec-policy` become inline-signed by default @iscchanges. The second is manual signing with
command-line tools. @tab:herramientas summarizes those shipped with BIND @bindarm.

#figure(
  tabla(
    columns: (auto, 1fr),
    hd[Tool], hd[Use],
    [`dnssec-keygen`], [Generates key pairs (KSK/ZSK) and their `.key` and `.private` metadata files.],
    [`dnssec-signzone`], [Signs a zone: adds `RRSIG`, `NSEC` or `NSEC3` records and generates the `dsset-` file.],
    [`dnssec-verify`], [Checks that a signed zone is correct.],
    [`dnssec-dsfromkey`], [Computes the `DS` record from the KSK, to hand to the parent zone.],
    [`dnssec-settime`], [Edits the publication, activation and retirement times of a key.],
    [`dnssec-revoke`], [Marks a key as revoked.],
    [`dnssec-importkey`], [Imports external DNSKEYs so that BIND can manage them.],
    [`dnssec-cds`], [Updates the child's `DS` from `CDS`/`CDNSKEY` records.],
    [`dnssec-keyfromlabel`], [Generates keys from a cryptographic module (HSM/PKCS\#11).],
    [`dnssec-ksr`], [Creates KSR/SKR files for offline-KSK setups (new in 9.20).],
    [`rndc dnssec`], [Queries or controls the state of zones with `dnssec-policy` (for example `-status`).],
    [`delv`, `dig +dnssec`], [Client-side queries and validation of results.],
  ),
  caption: [BIND tools related to DNSSEC.],
) <tab:herramientas>

== Manual workflow (applied to `alpha.unsigned`)

```bash
# 1. Keys (ECDSAP256SHA256): KSK and ZSK
dnssec-keygen -a ECDSAP256SHA256 -f KSK -n ZONE alpha.unsigned
dnssec-keygen -a ECDSAP256SHA256 -n ZONE alpha.unsigned

# 2. Include the DNSKEYs in the zone and sign (NSEC3 optional with -3)
cat Kalpha.unsigned.+013+*.key >> db.alpha.unsigned
dnssec-signzone -S -o alpha.unsigned -N unixtime db.alpha.unsigned

# 3. Verify and obtain the DS for the parent zone (unsigned)
dnssec-verify -o alpha.unsigned db.alpha.unsigned.signed
dnssec-dsfromkey Kalpha.unsigned.+013+<keytag>.key
```

In `named.conf`, the zone file is pointed to `db.alpha.unsigned.signed`. For the chain of trust to work, the `DS`
must be published in `db.unsigned`, and that zone and the root must be signed; the recursive server must enable
`dnssec-validation` with a trust anchor (`trust-anchors`) for the private root.

== Automatic workflow with `dnssec-policy`

```
zone "alpha.unsigned" {
    type primary;
    file "/var/lib/bind/db.alpha.unsigned";
    dnssec-policy default;
    inline-signing yes;
};
```

With this, `named` generates the keys, signs and re-signs the zone, and manages key rollovers; the state is
queried with `rndc dnssec -status alpha.unsigned`.


= Pending Items and Preliminary Conclusions

#list(
  [Capture the SOA/NS of the root and of `unsigned` (`dig @172.30.0.10 . SOA`, `dig @172.30.0.20 unsigned SOA`).],
  [Repeat the DNSSEC queries from a network without interception (phone hotspot, other resolvers) to obtain `RRSIG` and `NSEC`/`NSEC3`.],
  [Paste the full configuration files and document how the four `named` instances were started.],
  [Extend the script to also extract the message section, the `AA` flag and the SOA fields (serial, refresh, retry, expire, minimum).],
)

With the current evidence it is confirmed that the local tree resolves `www.alpha.unsigned` to `172.30.0.30`,
that the observed TTLs are consistent with the configured ones, and that the recursive server returns remaining
TTLs when answering from cache. On the public side, `starcke.mx` publishes DNSKEY records and has a `DS` record in its parent zone, which indicates that it is signed, but the responses obtained did not include signatures; this is provisionally attributed to the test network.

= Personal Conclusion (Angel Eduardo Luna)

Building the DNS tree by hand changed how I understand name resolution. Before this activity, I thought of
DNS as a single lookup. Running four `named` instances on loopback addresses and following one query from
the root to `unsigned` to `alpha.unsigned` showed me that resolution is a chain of delegations. Each server
only knows the next link, and the `AA` flag shows exactly which server is speaking with authority. The
capture made this concrete: the referrals from the root and from `unsigned` carry `AA=0`, and only `alpha`
answers with `AA=1`.

The TTL measurements taught me the most. Seeing the TTL on the recursive server drop from 86400 s to
83425 s, a difference that matched the 49 minutes between the two queries, showed that caching follows
exact rules and can be checked against the clock. The same reasoning explained the remaining TTLs returned
by 8.8.8.8 and the 10800 s cap that BIND applies to negative caching. Comparing our SOA values with RFC 1912
and RIPE-203 also showed me that values that work in a laboratory, such as a 7-day _expire_, would need a
justification in production.

The DNSSEC part was the most instructive because it did not go as expected. `starcke.mx` publishes DNSKEY
records and has a DS record in `.mx`, yet no `RRSIG` or `NSEC`/`NSEC3` records reached us, and the `AD`
flag was never set. Instead of assuming that DNSSEC "was not working", we had to read the trace carefully.
We noticed the `DO` bit in our queries, its absence in the responses, and root-server answers that carried
`RA=1`, and from that we formed a hypothesis about interception in the network. I learned that a security
mechanism only protects the client if the signatures actually reach a validator. A middlebox that strips
them makes a signed zone look unsigned without any visible error.

Finally, reviewing the BIND tools made it clear to me that signing a zone is the easy step. Keeping a chain
of trust working is harder: it requires publishing the DS in the parent, signing every level up to a trust
anchor, enabling validation on the resolver, and managing key rollovers over time. That is why I see
`dnssec-policy` as the reasonable choice for real deployments, while the manual workflow is the best way to
understand what is happening underneath. As a next step, I would like to sign our own `alpha.unsigned`,
`unsigned` and root zones and watch the local resolver set the `AD` flag.

= CRediT Author Statement (Angel Eduardo Luna)

@tab:credit lists only my contributions, by CRediT role @niso_credit_2022, consistent with the team
statement.

#figure(
  tabla(
    columns: (0.28fr, 0.72fr),
    hd[CRediT role], hd[Contribution],
    [Methodology], [Designed the structure of the report and of its revision: the audit of the first version, the feedback-to-fix traceability and the verification checklist.],
    [Writing – original draft], [Wrote the draft text of the report.],
    [Writing – review and editing], [Reviewed and edited the team's contributions, and reviewed the pull requests for the second version.],
    [Supervision], [Coordinated the team's work and the review of each member's changes.],
    [Project administration], [Set up and maintained the team repository, its branch rules, the modular templates and the build tooling, and assigned the team's tasks and deadlines.],
  ),
  caption: [My CRediT roles and the concrete contribution behind each one.],
) <tab:credit>

= Appendices

== Script `analizar_dns.py`

```python
import subprocess
import csv
from pathlib import Path

archivo = Path.home() / "captura_dns.pcapng"

comando = [
    "tshark", "-r", str(archivo),
    "-Y", "dns.flags.response == 1",
    "-T", "fields",
    "-e", "frame.number",
    "-e", "dns.qry.name",
    "-e", "dns.resp.name",
    "-e", "dns.resp.type",
    "-e", "dns.resp.ttl",
    "-E", "occurrence=a",
    "-E", "aggregator=|"
]

resultado = subprocess.run(
    comando, capture_output=True, text=True, check=True
)

tipos = {"1": "A", "2": "NS", "6": "SOA",
         "28": "AAAA", "43": "DS", "46": "RRSIG",
         "47": "NSEC", "48": "DNSKEY", "50": "NSEC3"}

registros = []

for linea in resultado.stdout.splitlines():
    campos = linea.split("\t")
    campos += [""] * (5 - len(campos))
    frame, consulta, nombres, tipos_rr, ttls = campos[:5]

    nombres = nombres.split("|")
    tipos_rr = tipos_rr.split("|")
    ttls = ttls.split("|")

    for nombre, tipo, ttl in zip(nombres, tipos_rr, ttls):
        if ttl:
            registros.append([
                frame, consulta, nombre,
                tipos.get(tipo, tipo), ttl
            ])

salida = Path.home() / "registros_dns.csv"

with open(salida, "w", newline="") as f:
    escritor = csv.writer(f)
    escritor.writerow([
        "Paquete", "Consulta", "Registro",
        "Tipo", "TTL_segundos"
    ])
    escritor.writerows(registros)

print("Registros extraidos:", len(registros))
print("Archivo generado:", salida)

for registro in registros:
    print(" | ".join(registro))

```

#bibliography(
  bytes("
bind920notes:
  type: web
  title: BIND 9.20 Release Notes
  url: https://ftp.arnes.si/pub/packages/bind9/9.20.0/doc/arm/html/notes.html
iscchanges:
  type: web
  title: BIND 9.20 Significant Changes (ISC Knowledge Base)
  url: https://kb.isc.org/docs/bind-920-changes
bindarm:
  type: web
  title: BIND 9 Administrator Reference Manual, 9.20
  url: https://ftp.yz.yamagata-u.ac.jp/pub/network/isc/bind9/9.20.24/doc/arm/html/index.html
rfc1912:
  type: web
  title: 'RFC 1912, Common DNS Operational and Configuration Errors'
  url: https://datatracker.ietf.org/doc/rfc1912/
ripe203:
  type: web
  title: RIPE-203, Recommended SOA values
  url: https://www.ripe.net/publications/docs/ripe-203
niso_credit_2022:
  type: report
  title: 'CRediT, Contributor Roles Taxonomy (ANSI/NISO Z39.104-2022)'
  author:
    name: National Information Standards Organization
  organization: NISO
  date: 2022
  serial-number:
    doi: 10.3789/ansi.niso.z39.104-2022
  url: https://credit.niso.org/
"),
  title: "References",
  style: "ieee",
)
