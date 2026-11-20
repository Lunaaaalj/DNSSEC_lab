// ============================================================
//  Technical report — Part 2 (draft)
//  arXiv-style template + DNS/BIND/DNSSEC lab content
// ============================================================

#let arxiv(
  title: [],
  authors: (),
  institution: "",
  abstract: none,
  keywords: (),
  date: "",
  professor: "",
  body,
) = {
  set document(title: title, author: authors.map(a => a.name))
  set page(
    paper: "us-letter",
    margin: (x: 1.1in, y: 1in),
    numbering: "1",
    number-align: center,
  )
  set text(font: "New Computer Modern", size: 11pt, lang: "en")
  set par(justify: true, leading: 0.62em, spacing: 0.9em)

  set heading(numbering: "1.1")
  show heading: it => {
    v(1.1em, weak: true)
    it
    v(0.6em, weak: true)
  }
  show heading.where(level: 1): set text(size: 13pt, weight: "bold")
  show heading.where(level: 2): set text(size: 11.5pt, weight: "bold")
  show heading.where(level: 3): set text(
    size: 11pt,
    weight: "bold",
    style: "italic",
  )

  set math.equation(numbering: "(1)")
  show link: set text(fill: rgb("#1a4fa0"))
  show ref: set text(fill: rgb("#1a4fa0"))
  show figure.caption: set text(size: 10pt)
  show raw: set text(size: 9pt)
  show raw.where(block: true): it => block(
    width: 100%,
    fill: luma(246),
    stroke: 0.4pt + luma(210),
    inset: 7pt,
    radius: 2pt,
    breakable: true,
    it,
  )
  set enum(indent: 1em)
  set list(indent: 1em)

  align(center)[
    #v(0.5em)
    #text(size: 17pt, weight: "bold")[#title]
    #v(1.2em)
    #grid(
      columns: calc.min(authors.len(), 2) * (1fr,),
      gutter: 1.5em,
      ..authors.map(a => [
        #text(size: 12pt)[*#a.name*] \
        #text(size: 10pt)[#a.at("affiliation", default: "")]
      ]),
    )

    #v(0.8em)
    \
    #text(size: 13pt)[Professor: #professor] \ \
    #text(size: 12pt)[#institution] \
    #text(size: 12pt)[#date] \

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
  rect(
    width: 100%,
    height: 2.6cm,
    stroke: (dash: "dashed", paint: gray),
    radius: 2pt,
  )[
    #align(center + horizon)[#text(
      fill: gray,
      size: 9.5pt,
    )[Insert screenshot: #desc]]
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
#let captura(path, cap, lbl, w: 80%) = [#figure(
    image(path, width: w),
    caption: cap,
  )#label(lbl)]

// ============================================================
#show: arxiv.with(
  title: [DNS Infrastructure with BIND and DNSSEC Analysis \ #text(size: 13pt, weight: "regular")[Technical report, part 2.]],
  authors: (
    (name: "Montserrat Rodríguez Ramírez", affiliation: "A01661271"),
    (name: "Jannette Cristina Flores Rodríguez", affiliation: "A01255711"),
    (name: "Angel Eduardo Luna", affiliation: "A00842657"),
    (name: "Carolina Sarahí Sánchez Meneses", affiliation: "A00227980"),
    (name: "Elías Alejandro Corral Rodríguez", affiliation: "A01743624"),
  ),

  professor: strong("Mohd Anas Wajid"),
  institution: "Tecnológico de Monterrey",
  date: "November 16, 2026",
  abstract: [
    This report documents the setup of a laboratory DNS tree (root, the `unsigned` TLD, the `alpha.unsigned`
    zone and a recursive resolver) using BIND 9.20.30 on loopback interfaces in Kali Linux, its verification
    with `named-checkconf` and `named-checkzone`, and the analysis of DNS traffic with TShark and a Python
    script that extracts SOA, NS and A records together with their TTL. DNSSEC records of the `starcke.mx`
    domain are then queried through the public resolver 8.8.8.8 and through the local resolver, and the
    results are compared. The public domain publishes DNSKEY and DS records and is signed: RRSIG and NSEC3 records were returned from a second network, whereas the same queries from the first network returned no signatures, which is analyzed as an environmental effect. Finally, the tools that BIND provides for signing zones with DNSSEC (automatic `dnssec-policy` and manual `dnssec-*` tools) are summarized.
  ],
  keywords: ("DNS", "BIND 9.20", "DNSSEC", "TTL", "TShark", "SOA"),
)

= Laboratory Setup

== Environment and addressing

The laboratory was implemented in a virtual machine running Kali Linux (arm64), using the loopback option
allowed by the instructions: each DNS server listens on a different IPv4 address bound to the `lo`
interface, so that four independent `named` instances coexist on the same host. BIND 9.20.30 was installed.

BIND was installed from the Kali repositories (@fig:bind-version):

```bash
sudo apt update
sudo apt install bind9 bind9-utils
named -v        # BIND 9.20.30-1-Debian
```

#figure(
  tabla(
    columns: (auto, auto, auto, 1fr),
    hd[Server],
    hd[Address],
    hd[Role],
    hd[Zone / function],
    [Root],
    [`172.30.0.10`],
    [Authoritative],
    [Zone `.`; delegates `unsigned.` to `ns.unsigned.`],
    [Unsigned],
    [`172.30.0.20`],
    [Authoritative (gTLD)],
    [Zone `unsigned.`; delegates `alpha.unsigned.`],
    [Alpha],
    [`172.30.0.30`],
    [Authoritative],
    [Zone `alpha.unsigned.`; contains `www`],
    [Recursive1],
    [`172.30.0.100`],
    [Recursive],
    [Resolves from the private root (_root hints_)],
  ),
  caption: [Laboratory servers.],
) <tab:servidores>

The addresses were assigned to the `lo` interface with `sudo ip addr add 172.30.0.10/32 dev lo` (and likewise for `.20`, `.30` and `.100`), as shown in @fig:loopback.

#captura(
  "01_Instalacion_BIND_version.png",
  [BIND 9.20.30 installation on Kali Linux and version check with `named -v`.],
  "fig:bind-version",
)
#captura(
  "02_IPs_loopback.png",
  [IPv4 addresses assigned to the `lo` interface for the four servers.],
  "fig:loopback",
)

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

The configuration files of the four servers are shown below; `alpha` is the one designed by the team. The files are kept in `~/dns-lab` and copied to `/etc/bind/dns-lab`, which is where each `named` loads them from. Compared with the base files, each instance has its own `pid-file` and `controls { };`, so that the four instances do not share the PID file or the `rndc` control channel.

```
// root/named.conf
options {
    directory "/var/cache/bind";
    pid-file "/run/named-root.pid";
    listen-on { 172.30.0.10; };
    listen-on-v6 { none; };
    recursion no;
    allow-query { any; };
};
zone "." {
    type primary;
    file "/etc/bind/dns-lab/root/zones/db.root";
};
controls { };
```

```
; root/zones/db.root
$TTL 86400
@ IN SOA ns.root. admin.root. ( 2026111601 3600 900 604800 86400 )
@ IN NS ns.root.
ns.root. IN A 172.30.0.10
; Delegation to unsigned
unsigned. IN NS ns.unsigned.
ns.unsigned. IN A 172.30.0.20
```

```
// unsigned/named.conf
options {
    directory "/var/cache/bind";
    pid-file "/var/cache/bind/unsigned.pid";
    listen-on { 172.30.0.20; };
    listen-on-v6 { none; };
    recursion no;
    allow-query { any; };
};
zone "unsigned" {
    type primary;
    file "/etc/bind/dns-lab/unsigned/zones/db.unsigned";
};
controls { };
```

```
; unsigned/zones/db.unsigned
$TTL 86400
@ IN SOA ns.unsigned. admin.unsigned. ( 2026111601 3600 900 604800 86400 )
@ IN NS ns.unsigned.
ns.unsigned. IN A 172.30.0.20
; Delegation to alpha.unsigned
alpha.unsigned. IN NS ns.alpha.unsigned.
ns.alpha.unsigned. IN A 172.30.0.30
```

```
// alpha/named.conf
options {
    directory "/var/cache/bind";
    pid-file "/var/cache/bind/alpha.pid";
    listen-on { 172.30.0.30; };
    listen-on-v6 { none; };
    recursion no;
    allow-query { any; };
};
zone "alpha.unsigned" {
    type primary;
    file "/etc/bind/dns-lab/alpha/zones/db.alpha.unsigned";
};
controls { };
```

```
; alpha/zones/db.alpha.unsigned
$TTL 86400
@ IN SOA ns.alpha.unsigned. admin.alpha.unsigned. ( 2026111601 3600 900 604800 86400 )
@ IN NS ns.alpha.unsigned.
ns.alpha.unsigned. IN A 172.30.0.30
www IN A 172.30.0.30
```

```
// recursive1/named.conf
options {
    directory "/var/cache/bind";
    pid-file "/var/cache/bind/recursive1.pid";
    listen-on { 172.30.0.100; };
    listen-on-v6 { none; };
    recursion yes;
    allow-recursion { 127.0.0.1; 172.30.0.0/24; };
    allow-query { 127.0.0.1; 172.30.0.0/24; };
    dnssec-validation no;
};
zone "." {
    type hint;
    file "/etc/bind/dns-lab/recursive1/zones/db.root.hints";
};
controls { };
```

```
; recursive1/zones/db.root.hints
. 86400 IN NS ns.root.
ns.root. 86400 IN A 172.30.0.10
```


The zone of `alpha` includes the `A` record for `www` inside the same zone file, as the activity requires. Its SOA and NS values match those observed later in the capture (@tab:registros).

The consistency of the tree depends on the delegations: the root delegates `unsigned.` (`NS ns.unsigned.` with
glue `172.30.0.20`) and `unsigned` delegates `alpha.unsigned.` (`NS ns.alpha.unsigned.` with glue
`172.30.0.30`). Both delegations were confirmed in the captured traffic (packets 2 and 4).

== Starting the servers

The four instances were started with the following commands (the root server in the foreground, in its own terminal, and the others in the background):

```bash
sudo named -4 -g -c /etc/bind/dns-lab/root/named.conf
sudo named -4 -c /etc/bind/dns-lab/unsigned/named.conf
sudo named -4 -c /etc/bind/dns-lab/alpha/named.conf
sudo named -4 -c /etc/bind/dns-lab/recursive1/named.conf
```

@fig:procesos shows the four `named` processes and the sockets listening on port 53, one per address.

#captura(
  "18_Instancias_named_activas.png",
  [Running `named` processes and UDP sockets on port 53 (one per laboratory address).],
  "fig:procesos",
  w: 110%,
)


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

No messages were produced by `named-checkconf` at any of the four levels, and `named-checkzone` ended with `OK` for the three zones (@fig:check-root, @fig:check-unsigned and @fig:check-alpha). The recursive server has no zone file of its own, so it was verified with `named-checkconf` and by displaying `db.root.hints` (@fig:check-recursive). All three zones load with serial `2026111601`. A warning (_has no addresses records_) appears for `ns.unsigned` in `root` and for `ns.alpha.unsigned` in `unsigned`. It is a warning, not an error, and the instructions state that `OK` is the expected result regardless of warnings. The `-D` dump of the root zone shows the `A` record of `ns.unsigned`, and the queries of the next section confirm that both delegations return their glue records (@fig:dig-root and @fig:dig-unsigned).

#captura(
  "03_Root_validacion_delegacion.png",
  [Verification of the `root` server, with a dump of the root zone (`-D`).],
  "fig:check-root",
)
#captura(
  "04_Unsigned_validacion.png",
  [Verification of the `unsigned` server.],
  "fig:check-unsigned",
)
#captura(
  "05_Alpha_registro_A_y_validacion.png",
  [Verification of the `alpha` server and its `A` record for `www`.],
  "fig:check-alpha",
)
#captura(
  "06_Recursivo_root_hints.png",
  [Verification of the recursive server and contents of `db.root.hints`.],
  "fig:check-recursive",
)

= Tests with `dig` and Traffic Capture

== Methodology

Traffic was captured on the `lo` interface, filtering port 53. On the first machine, because of problems with Wireshark’s graphical interface, TShark was used; Wireshark was used later to inspect the traces. Queries were issued with `dig` to each server in the tree and to the
recursive server, and the resulting trace (`captura_dns.pcapng`, 12 packets) was processed with the script
`analizar_dns.py` (appendix; first version, later extended into `analizar_dns_v2.py`), which calls `tshark` with the filter `dns.flags.response == 1` and exports the
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

#captura(
  "07_Root_delegacion_a_unsigned.png",
  [Query to the root server: delegation of `unsigned` with glue record.],
  "fig:dig-root",
  w: 70%,
)
#captura(
  "08_Unsigned_delegacion_a_alpha.png",
  [Query to `unsigned`: delegation of `alpha.unsigned` with glue record.],
  "fig:dig-unsigned",
)
#captura(
  "09_Alpha_respuesta_A_autoritativa.png",
  [Authoritative answer (`aa`) from `alpha` for `www.alpha.unsigned`.],
  "fig:dig-alpha",
)


== Extracted records

The script extracted 13 records. @tab:registros lists them. The extended version of the script (appendix) also exports the message section, the authority flag (`AA`), the recursion-available flag (`RA`) and the record data, including the full SOA.

#figure(
  tabla(
    columns: (auto, auto, auto, auto, auto, auto, 1fr),
    hd[Pkt],
    hd[Server],
    hd[Record],
    hd[Type],
    hd[TTL (s)],
    hd[Section],
    hd[Data / remark],
    [2],
    [Root `.10`],
    [`unsigned`],
    [NS],
    [86400],
    [Authority],
    [`ns.unsigned`, `AA=0` (referral)],
    [2],
    [Root `.10`],
    [`ns.unsigned`],
    [A],
    [86400],
    [Additional],
    [`172.30.0.20` (glue)],
    [4],
    [Unsigned `.20`],
    [`alpha.unsigned`],
    [NS],
    [86400],
    [Authority],
    [`ns.alpha.unsigned`, `AA=0` (referral)],
    [4],
    [Unsigned `.20`],
    [`ns.alpha.unsigned`],
    [A],
    [86400],
    [Additional],
    [`172.30.0.30` (glue)],
    [6],
    [Alpha `.30`],
    [`alpha.unsigned`],
    [SOA],
    [86400],
    [Answer],
    [`AA=1`; see @tab:soa],
    [6],
    [Alpha `.30`],
    [`alpha.unsigned`],
    [NS],
    [86400],
    [Authority],
    [`ns.alpha.unsigned`],
    [6],
    [Alpha `.30`],
    [`ns.alpha.unsigned`],
    [A],
    [86400],
    [Additional],
    [`172.30.0.30`],
    [8],
    [Alpha `.30`],
    [`alpha.unsigned`],
    [NS],
    [86400],
    [Answer],
    [`AA=1`],
    [8],
    [Alpha `.30`],
    [`ns.alpha.unsigned`],
    [A],
    [86400],
    [Additional],
    [`172.30.0.30`],
    [10],
    [Alpha `.30`],
    [`www.alpha.unsigned`],
    [A],
    [86400],
    [Answer],
    [`172.30.0.30`, `AA=1`],
    [10],
    [Alpha `.30`],
    [`alpha.unsigned`],
    [NS],
    [86400],
    [Authority],
    [`ns.alpha.unsigned`],
    [10],
    [Alpha `.30`],
    [`ns.alpha.unsigned`],
    [A],
    [86400],
    [Additional],
    [`172.30.0.30`],
    [12],
    [Recursive `.100`],
    [`www.alpha.unsigned`],
    [A],
    [*83425*],
    [Answer],
    [`172.30.0.30`, `AA=0`, `RA=1`],
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
    hd[Field],
    hd[Measured value],
    hd[Reference],
    hd[Comment],
    [MNAME],
    [`ns.alpha.unsigned.`],
    [—],
    [Consistent with the zone's NS],
    [RNAME],
    [`admin.alpha.unsigned.`],
    [—],
    [Administrator contact],
    [Serial],
    [2026111601],
    [YYYYMMDDnn],
    [Recommended format],
    [Refresh],
    [3600 s],
    [1200–43200 (RFC 1912); 86400 (RIPE-203)],
    [Within the RFC 1912 range],
    [Retry],
    [900 s],
    [7200 (RIPE-203)],
    [Shorter than refresh; more aggressive than RIPE-203],
    [Expire],
    [604800 s (7 d)],
    [1209600–2419200 (RFC 1912); 3600000 (RIPE-203)],
    [Below both references],
    [Minimum],
    [86400 s],
    [172800 (RIPE-203)],
    [Negative-caching TTL],
  ),
  caption: [SOA of `alpha.unsigned` against recommended values.],
) <tab:soa>

@tab:soa-zonas shows the SOA of the three zones of the tree. All of them use the timers of the base files provided by the instructor and differ only in MNAME, RNAME and the zone name.

#figure(
  tabla(
    columns: (1.8fr, 2.3fr, 2.6fr, 1.2fr, .9fr, .7fr, .8fr, .1fr),
    hd[Zone],
    hd[MNAME],
    hd[RNAME],
    hd[Serial],
    hd[Refresh],
    hd[Retry],
    hd[Expire],
    hd[Min.],
    [`.` (root)],
    [`ns.root.`],
    [`admin.root.`],
    [2026111601],
    [3600],
    [900],
    [604800],
    [86400],
    [`unsigned.`],
    [`ns.unsigned.`],
    [`admin.unsigned.`],
    [2026111601],
    [3600],
    [900],
    [604800],
    [86400],
    [`alpha.unsigned.`],
    [`ns.alpha.unsigned.`],
    [`admin.alpha.unsigned.`],
    [2026111601],
    [3600],
    [900],
    [604800],
    [86400],
  ),
  caption: [SOA records of the three zones (seconds).],
) <tab:soa-zonas>


The refresh (3600 s) falls inside the range recommended by RFC 1912 and the retry (900 s) is shorter than the refresh, as expected. The expire value (604800 s, 7 days) is lower than the 2 to 4 weeks suggested by RFC 1912 and the 3600000 s of RIPE-203. We kept it because it comes from the base files provided for the activity, and in this laboratory each zone has a single server, so there are no secondary servers whose copy could expire. In a production deployment it would be raised to at least 1209600 s.

== Resolution through the recursive server

The instructions ask for the queries to be made through the recursive server. A second capture (`captura_dns_recursivo.pcapng`, 30 packets, interface `lo`) was taken issuing every query to `172.30.0.100`, taken right after restarting the recursive instance (`rndc` is disabled by `controls { };`, so a restart was used to empty its cache), so its cache was empty at the first query:

```bash
dig @172.30.0.100 www.alpha.unsigned. A
dig @172.30.0.100 . SOA
dig @172.30.0.100 unsigned. SOA
dig @172.30.0.100 unsigned. NS
dig @172.30.0.100 alpha.unsigned. SOA
dig @172.30.0.100 alpha.unsigned. NS
dig @172.30.0.100 www.alpha.unsigned. A
```

@tab:recursivo summarizes the trace. Since `dig` runs on the same host as the recursive server, the client queries also appear with source `172.30.0.100`.

#figure(
  tabla(
    columns: (auto, auto, 1.2fr, auto, 1.6fr),
    hd[Pkt],
    hd[From → To],
    hd[Message],
    hd[Flags],
    hd[Content (TTL)],
    [1],
    [client → `.100`],
    [`www.alpha.unsigned A`],
    [`RD=1`],
    [Client query],
    [2],
    [`.100` → `.10`],
    [`. NS`],
    [`RD=0`],
    [Priming query toward the root hints],
    [3],
    [`.100` → `.10`],
    [`unsigned NS`],
    [`RD=0`],
    [Only the next label is sent],
    [4],
    [`.10` → `.100`],
    [Referral],
    [`AA=0`],
    [NS `ns.unsigned`; glue `172.30.0.20` (86400)],
    [5],
    [`.10` → `.100`],
    [Answer to `. NS`],
    [`AA=1`],
    [`ns.root` (86400)],
    [6],
    [`.100` → `.20`],
    [`alpha.unsigned NS`],
    [`RD=0`],
    [Only the next label is sent],
    [7],
    [`.20` → `.100`],
    [Referral],
    [`AA=0`],
    [NS `ns.alpha.unsigned`; glue `172.30.0.30` (86400)],
    [8],
    [`.100` → `.30`],
    [`www.alpha.unsigned A`],
    [`RD=0`],
    [Full name],
    [9],
    [`.30` → `.100`],
    [Answer],
    [`AA=1`],
    [`172.30.0.30` (86400)],
    [10],
    [`.100` → client],
    [Answer],
    [`AA=0`, `RA=1`],
    [`172.30.0.30` (86400)],
    [11–16],
    [client, `.100`, `.10`],
    [`. SOA`],
    [`AA=1` (14), `RA=1` (16)],
    [SOA of root (86400); extra `. NS` query in 13 and 15],
    [17–20],
    [client, `.100`, `.20`],
    [`unsigned SOA`],
    [`AA=1` (19), `RA=1` (20)],
    [SOA of `unsigned` (86400)],
    [21–22],
    [client ↔ `.100`],
    [`unsigned NS`],
    [`AA=0`, `RA=1`],
    [From cache, no traffic toward `.20` (86400)],
    [23–26],
    [client, `.100`, `.30`],
    [`alpha.unsigned SOA`],
    [`AA=1` (25), `RA=1` (26)],
    [SOA of `alpha` (86400)],
    [27–28],
    [client ↔ `.100`],
    [`alpha.unsigned NS`],
    [`AA=0`, `RA=1`],
    [From cache (86400)],
    [29–30],
    [client ↔ `.100`],
    [`www.alpha.unsigned A`],
    [`AA=0`, `RA=1`],
    [From cache; TTL 86398, 2.08 s after packet 1],
  ),
  caption: [Resolution through the recursive server (`captura_dns_recursivo.pcapng`).],
) <tab:recursivo>

// #captura("21_Wireshark_recursivo.png", [Resolution of `www.alpha.unsigned` through the recursive server (Wireshark, filter `dns`).], "fig:wireshark-rec")

The recursive server walked the tree from the private root: the referrals of the root and of `unsigned` carry `AA=0` and glue, and only `alpha` answers with `AA=1`. The server sends only the next label to each level (`unsigned` to the root, `alpha.unsigned` to `unsigned`) and the full name only to the last server, which is consistent with QNAME minimization. All TTLs are 86400 s, as configured, and the repeated queries are answered from cache with the TTL already decreased.

== TTL on the recursive server

The first query for `www.alpha.unsigned` to the recursive server (@fig:recursive, 12:12:39) returned the full TTL, 86400 s, because the server resolved the name from the private root and cached the answer. When the query was repeated during the capture (packet 12 of @tab:registros, 13:02:14), the TTL was 83425 s. The difference, 2975 s (49 min 35 s), matches the time elapsed between both queries: the recursive server did not query the authoritative servers again (there is no traffic toward them between packets 11 and 12) and answered from its cache, with `RA=1` and `AA=0`, returning the remaining TTL. The second capture confirms the same behavior over a short interval: the first answer (packet 10) carries 86400 s and the repeated query 2.08 s later (packet 30) carries 86398 s, with no traffic toward the authoritative servers in between.

#captura(
  "10_Recursivo_resuelve_www_alpha.png",
  [Query to the recursive server `172.30.0.100` (12:12:39): TTL 86400 s.],
  "fig:recursive",
)

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


#captura(
  "17_TShark_trafico_DNSSEC_guardado.png",
  [DNSSEC traffic capture with TShark and last queries (`+edns=0 +bufsize=1232 +tcp`).],
  "fig:tshark",
  w: 80%,
)

=== Second network

The queries were repeated from a second Kali machine, connected to a different network, capturing on the `any` interface (without promiscuous mode) and writing the trace to `/tmp`:

```bash
sudo tshark -i any -p -f "port 53" -a duration:120 -w /tmp/captura_dnssec_kali.pcapng
dig @8.8.8.8 +dnssec starcke.mx SOA      # also NS, A, AAAA, DNSKEY, DS and RRSIG
dig @8.8.8.8 +dnssec noexiste-xyz.starcke.mx A
dig @8.8.8.8 +dnssec +cd starcke.mx A
dig @8.8.8.8 +dnssec +tcp starcke.mx A
delv @8.8.8.8 starcke.mx A
delv @8.8.8.8 starcke.mx DNSKEY
```

The trace `captura_dnssec_kali.pcapng` was processed with the extended script, which produced `captura_dnssec_kali.csv`. @fig:wireshark-kali shows the responses that carry `RRSIG` or `NSEC3` records. In the first one (packet 2, the SOA) the flags are `0x81a0` (response, recursion desired and available, and `AD` set) and the `OPT` record returns `Z: 0x8000`, that is, the `DO` bit.

#captura(
  "20_Wireshark_RRSIG_NSEC3.png",
  [Responses from 8.8.8.8 with `RRSIG` or `NSEC3` records in the second network (Wireshark filter `dns.resp.type == 46 || dns.resp.type == 50`).],
  "fig:wireshark-kali",
  w: 85%,
)

== Results with 8.8.8.8 (first network)

#figure(
  tabla(
    columns: (auto, 1fr, auto, auto, auto),
    hd[Record],
    hd[Content],
    hd[TTL (s)],
    hd[TTL in capture (s)],
    hd[Source],
    [SOA],
    [`ns1.teuto.net. hostmaster.teuto.net. 2026111502 28000 7200 604800 86400`],
    [7200],
    [7078 (pkt. 26)],
    [@fig:g-dnskey],
    [NS],
    [`ns1.teuto.net.`, `ns2.teuto.net.`, `ns3.teuto.net.` (glue A: `212.15.202.2`, `212.15.202.3`, `212.15.205.12`, TTL 106 to 108 s)],
    [7200],
    [—],
    [@fig:g-ns],
    [A],
    [`212.8.207.35`],
    [7200],
    [7077 (pkt. 16)],
    [@fig:g-ns],
    [AAAA],
    [`2001:ae2:207::1:eb:2`],
    [7200],
    [—],
    [@fig:g-ns],
    [DNSKEY],
    [Two keys, algorithm 13 (ECDSAP256SHA256): KSK (flags 257) and ZSK (flags 256)],
    [7200],
    [6884 (pkt. 6)],
    [@fig:g-dnskey],
    [DS],
    [`25609 13 2 7888AD62…` (SHA-256)],
    [86400],
    [—],
    [@fig:g-dnskey],
    [RRSIG],
    [Not observed from this network (see @tab:dnssec-b)],
    [—],
    [—],
    [@fig:nsec],
    [NSEC/NSEC3],
    [Not observed from this network; the non-existent name returned only the SOA (see @tab:dnssec-b)],
    [—],
    [—],
    [@fig:nsec],
  ),
  caption: [Records obtained for `starcke.mx` via 8.8.8.8 from the first network.],
) <tab:dnssec>

When queried directly (@fig:g-dnskey and @fig:g-ns), 8.8.8.8 returned 7200 s for every record of the `starcke.mx` zone (SOA, NS, A, AAAA and DNSKEY), which indicates that the TTL configured in the zone is 7200 s. The `DS` record has a TTL of 86400 s because it is published by the parent zone (`.mx`), which sets that value. The TTLs in the capture are remaining values in Google's cache: they are lower than the 7200 s of the zone and decrease with the time since the record was cached. Since 8.8.8.8 is an anycast service that may use several caches, the decrease is not always strictly monotonic.

#figure(
  tabla(
    columns: (auto, 1.5fr, auto, auto, 1.2fr),
    hd[Record],
    hd[Content],
    hd[TTL (s)],
    hd[TTL in capture (s)],
    hd[RRSIG / remark],
    [SOA],
    [`ns1.teuto.net. hostmaster.teuto.net. 2026111502 28000 7200 604800 86400`],
    [7200],
    [7200 (pkt. 2)],
    [Signed by key tag 17096; `AD=1`],
    [NS],
    [`ns1.teuto.net.`, `ns2.teuto.net.`, `ns3.teuto.net.`],
    [7200],
    [7200 (pkt. 4)],
    [Signed by 17096; `AD=1`],
    [A],
    [`212.8.207.35`],
    [7200],
    [7074 (pkt. 18)],
    [Signed by 17096; `AD=1`],
    [AAAA],
    [`2001:ae2:207::1:eb:2`],
    [7200],
    [7014 (pkt. 20)],
    [Signed by 17096; `AD=1`],
    [DNSKEY],
    [Flags 256 (ZSK, tag 17096) and 257 (KSK, tag 25609), algorithm 13],
    [7200],
    [7069 (pkt. 22)],
    [Two RRSIG, by 25609 and 17096; `AD=1`],
    [DS],
    [`25609 13 2 7888AD62…` (SHA-256)],
    [86400 (original)],
    [17294 (pkt. 24)],
    [Signed by `mx.` (tag 106, algorithm 8); `AD=1`],
    [RRSIG],
    [9 signatures: DNSKEY (2), AAAA, MX, SOA, TXT, A, NSEC3PARAM, NS],
    [7200 (NSEC3PARAM: 0)],
    [7200 and 0 (pkt. 26)],
    [Valid from 2026-11-15 to 2026-12-01],
    [NSEC3],
    [3 records (`1 1 0 -`, SHA-1, opt-out) for `noexiste-xyz.starcke.mx`],
    [7200],
    [7200 (pkt. 28)],
    [Each with its RRSIG; SOA TTL 1800],
  ),
  caption: [Records of `starcke.mx` via 8.8.8.8 from the second network.],
) <tab:dnssec-b>

The `original TTL` field of the RRSIGs confirms the TTLs published by each zone: 7200 s for `starcke.mx` and 86400 s for the `DS`, which is published by `mx.`. In the first `dig` from the second network the resolver reported 21600 s for the `DS`, below the 86400 s published by `mx.`, and in the capture, taken later, 17294 s, so the reported value is lower than the published one and decreases with time. This is consistent with the resolver limiting the TTL of cached records, although we did not confirm it. The other TTLs in the capture (7074 s for `A`, 7069 s for `DNSKEY` and 7014 s for `AAAA`) are remaining values in the cache of 8.8.8.8, below the 7200 s of the zone. The chain of trust is consistent: the `DS` (key tag 25609) points to the KSK that signs the DNSKEY set, and the `DS` itself is signed by the parent zone.

The `+cd` (checking disabled) query returned the same `A` record and its `RRSIG`, but without the `AD` flag (`qr rd ra cd`), whereas the query without `+cd` returned `qr rd ra ad`. The `RRSIG` query itself came back without `AD`, since it is a query for the signatures and not for validated data. In addition, `delv` validated the chain of trust on the client side: both `starcke.mx A` and `starcke.mx DNSKEY` ended with `; fully validated`, so the result does not depend only on the `AD` flag set by 8.8.8.8 (@fig:delv).

#captura(
  "19_delv_fully_validated.png",
  [`delv` validation of `starcke.mx A` and `DNSKEY`, and effect of `+cd` on the `AD` flag.],
  "fig:delv",
  w: 105%,
)

#captura(
  "13_Google_DNSKEY_DS_SOA.png",
  [DNSKEY, DS and SOA of `starcke.mx` via 8.8.8.8.],
  "fig:g-dnskey",
  w: 80%,
)

#captura(
  "14_Google_NS_A_AAAA.png",
  [NS, A and AAAA of `starcke.mx` via 8.8.8.8 (TCP).],
  "fig:g-ns",
  w: 100%,
)

== Comparison with the local recursive server

For the local recursive server, the query `starcke.mx A` returns `NXDOMAIN` with `RA=1` and `AD=0` (packet 32).
The authority section contains the SOA of the private root (`ns.root. admin.root. 2026111601 3600 900 604800
86400`) with a TTL of 10492 s, which is the remaining negative TTL in cache. This is expected: the recursive
server only knows the laboratory root, which does not delegate the `mx` TLD, so it cannot resolve Internet names.
In addition, validation was disabled (`dnssec-validation no`), so it will never set `AD`.

#figure(
  tabla(
    columns: (auto, 1fr, 1fr),
    hd[Aspect],
    hd[8.8.8.8],
    hd[Local recursive `172.30.0.100`],
    [Result of `starcke.mx A`],
    [`NOERROR`, `212.8.207.35`],
    [`NXDOMAIN`],
    [Source of authority],
    [Public DNS (real root, `.mx`, `starcke.mx`)],
    [Laboratory private root],
    [SOA returned],
    [`ns1.teuto.net.` (zone `starcke.mx`)],
    [`ns.root.` (private zone `.`)],
    [DNSSEC validation],
    [Supported by the service],
    [Disabled (`dnssec-validation no`)],
    [Chain of trust],
    [Real root → `mx` → `starcke.mx`],
    [Does not exist],
  ),
  caption: [Differences between the two resolvers.],
) <tab:comparacion>

The same eight record types were queried through the local recursive server (@tab:ocho). All of them returned `NXDOMAIN`, without `AD`, with the SOA of the private root in the authority section, and with `DO` set in the response `OPT` (`udp: 1232`).

#figure(
  tabla(
    columns: (auto, 1.4fr, 1.4fr),
    hd[Type],
    hd[8.8.8.8 (second network)],
    hd[Local recursive `172.30.0.100`],
    [SOA],
    [SOA + RRSIG; `AD=1`],
    [`NXDOMAIN`; SOA of `.`],
    [NS],
    [3 NS + RRSIG; `AD=1`],
    [`NXDOMAIN`; SOA of `.`],
    [A],
    [`212.8.207.35` + RRSIG; `AD=1`],
    [`NXDOMAIN`; SOA of `.`],
    [AAAA],
    [`2001:ae2:207::1:eb:2` + RRSIG; `AD=1`],
    [`NXDOMAIN`; SOA of `.`],
    [DNSKEY],
    [2 keys + 2 RRSIG; `AD=1`],
    [`NXDOMAIN`; SOA of `.`],
    [DS],
    [`25609 13 2 …` + RRSIG by `mx.`; `AD=1`],
    [`NXDOMAIN`; SOA of `.`],
    [RRSIG],
    [9 signatures; no `AD`],
    [`NXDOMAIN`; SOA of `.`],
    [NSEC/NSEC3],
    [3 NSEC3 + RRSIG (non-existent name); SOA TTL 1800],
    [`NXDOMAIN`; SOA of `.`],
  ),
  caption: [`starcke.mx` queried with `+dnssec` through both resolvers.],
) <tab:ocho>


The negative TTL of the private root's SOA was 10800 s on the first query (@fig:local, 13:06:37) and then decreased (10606 s at 13:09:51 and 10492 s at 13:11:45, see @fig:nsec and @fig:tshark). It is lower than the `minimum` of the SOA (86400 s) because BIND limits negative caching by default to three hours (`max-ncache-ttl`, 10800 s). Another difference is that the response of the local server does return the `DO` flag in the `OPT` pseudo-record, even though it does not validate (`AD=0`) because of `dnssec-validation no`. The responses from 8.8.8.8 received on the first network did not return it, whereas on the second network they did.

#captura(
  "15_Comparacion_recursivo_local_NXDOMAIN.png",
  [Query for `starcke.mx` to the local recursive server: `NXDOMAIN`.],
  "fig:local",
  w: 100%,
)

== Absence of RRSIG and NSEC/NSEC3

The zone does publish DNSSEC keys (a DNSKEY with algorithm 13), so `RRSIG` records were expected. In the traces captured from the first network, the queries to 8.8.8.8 carry the `DO` bit (EDNS, flag `0x8000`), but the responses contain no `RRSIG`, the response `OPT` does not return `DO`, and `AD=0`. The query for a non-existent name (`noexiste-20261116.starcke.mx`) returned only the SOA, with no `NSEC`/`NSEC3`.

To check whether this was caused by the test environment, the same queries were repeated from a second network (another team member's Kali machine). There, 8.8.8.8 returned `RRSIG` records for every RRset, the response `OPT` included `DO`, the `AD` flag was set on the positive answers (@tab:dnssec-b) and the non-existent name returned three `NSEC3` records with their signatures. Therefore, the zone is correctly signed and the public resolver does return the signatures; the absence observed on the first network is an effect of that network or machine, not of the queries or of the zone.

The exact cause was not isolated. Two checks would help discriminate between interception in the network and a problem of the virtual machine: querying other public resolvers (for example 1.1.1.1 and 9.9.9.9) and using DNS over TLS (`kdig +tls`), which bypasses port 53. They were not run from the first network and are left as future work.



#captura(
  "16_Prueba_inexistencia_NSEC_no_observado.png",
  [RRSIG query and non-existent name query via 8.8.8.8: no RRSIG or NSEC/NSEC3 records are returned. (first network)],
  "fig:nsec",
  w: 95%,
)

The RRSIG query and the non-existent-name query are shown in @fig:nsec.

The first network's VM uses `192.168.64.1`, the virtual network gateway (the host), as its DNS server (`/etc/resolv.conf` generated by NetworkManager). The background traffic toward real root servers comes from `192.168.64.2`, the VM itself, and consists only of `NS` and `DNSKEY` queries for the root zone, which is what a validating resolver does when it starts. It begins right after the query to the local recursive server, so it could come from a process of the VM or from the lab itself. The search domains of that machine (`svcs.itesm.mx`, `itesm.mx`, `mty.itesm.mx`) show that it was connected through the university network, so if an interception is confirmed it would be located in that network or in the host, and not necessarily in the virtualization. In the trace of the second network, the only other DNS responses come from the same gateway (`192.168.64.1`) for ordinary names (`play.google.com`, `docs.google.com`), so that machine also uses the gateway as its resolver, and no queries toward real root servers appear. The traffic toward the root servers was therefore observed only on the first machine.

= BIND Tools for DNSSEC Signing

BIND 9.20 offers two approaches. The first is automatic signing with `dnssec-policy`, which since 9.20 is the
only option for signing managed by `named`, because `auto-dnssec` was removed @bind920notes. In 9.20, zones
configured with `dnssec-policy` become inline-signed by default @iscchanges. The second is manual signing with
command-line tools. @tab:herramientas summarizes those shipped with BIND @bindarm.

#figure(
  tabla(
    columns: (auto, 1fr),
    hd[Tool],
    hd[Use],
    [`dnssec-keygen`],
    [Generates key pairs (KSK/ZSK) and their `.key` and `.private` metadata files.],
    [`dnssec-signzone`],
    [Signs a zone: adds `RRSIG`, `NSEC` or `NSEC3` records and generates the `dsset-` file.],
    [`dnssec-verify`],
    [Checks that a signed zone is correct.],
    [`dnssec-dsfromkey`],
    [Computes the `DS` record from the KSK, to hand to the parent zone.],
    [`dnssec-settime`],
    [Edits the publication, activation and retirement times of a key.],
    [`dnssec-revoke`],
    [Marks a key as revoked.],
    [`dnssec-importkey`],
    [Imports external DNSKEYs so that BIND can manage them.],
    [`dnssec-cds`],
    [Updates the child's `DS` from `CDS`/`CDNSKEY` records.],
    [`dnssec-keyfromlabel`],
    [Generates keys from a cryptographic module (HSM/PKCS\#11).],
    [`dnssec-ksr`],
    [Creates KSR/SKR files for offline-KSK setups (new in 9.20).],
    [`rndc dnssec`],
    [Queries or controls the state of zones with `dnssec-policy` (for example `-status`).],
    [`delv`, `dig +dnssec`],
    [Client-side queries and validation of results.],
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

This workflow was not run in the laboratory; it describes how `alpha.unsigned` would be signed.

In `named.conf`, the zone file is pointed to `db.alpha.unsigned.signed`. For the chain of trust to work, the `DS`
must be published in `db.unsigned`, and that zone and the root must be signed; the recursive server must enable
`dnssec-validation` with a trust anchor (`trust-anchors`) for the private root.

== Automatic workflow with `dnssec-policy`

```
zone "alpha.unsigned" {
    type primary;
    file "/etc/bind/dns-lab/alpha/zones/db.alpha.unsigned";
    dnssec-policy default;
};
```

Note: in this laboratory `controls { };` disables `rndc`; to use `rndc dnssec -status`, the instance would need a `controls` block with its own `inet` address/port and key.

With this, `named` generates the keys, signs and re-signs the zone, and manages key rollovers; the state is
queried with `rndc dnssec -status alpha.unsigned`.


= Conclusions

The local tree resolves `www.alpha.unsigned` to `172.30.0.30` through the private root, the observed TTLs (86400 s) match the configured `$TTL`, and the recursive server returns the remaining TTL when it answers from cache. The SOA timers come from the instructor's base files; the expire value (604800 s) is lower than the recommended range and would be raised in a production deployment.

On the public side, `starcke.mx` is signed (algorithm 13, `DS` published in `.mx`). From the second network, 8.8.8.8 returned `RRSIG` and `NSEC3` records and set `AD`, and `delv` validated the chain of trust. From the first network, the same queries returned no signatures and no `AD` flag; this points to an environmental effect, possibly DNS interception in the network of the first machine, whose exact cause was not isolated. The local recursive server cannot resolve Internet names and does not validate DNSSEC, so the comparison with 8.8.8.8 shows differences both in the source of authority and in validation. BIND 9.20 offers `dnssec-policy` for automatic signing and the `dnssec-*` tools for manual signing; the workflow was described but not run on `alpha.unsigned`, so signing the tree and enabling validation in the recursive server is the natural next step.

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

== Script `analizar_dns_v2.py`

```python
#!/usr/bin/env python3
import csv
import subprocess
import sys
from pathlib import Path

if len(sys.argv) < 2:
    print("Uso: python3 analizar_dns_v2.py captura.pcapng [salida.csv]")
    sys.exit(1)

archivo = Path(sys.argv[1])
salida = Path(sys.argv[2]) if len(sys.argv) > 2 else archivo.with_suffix(".csv")

campos = [
    "frame.number", "ip.src", "dns.qry.name",
    "dns.flags.authoritative", "dns.flags.recavail",
    "dns.count.answers", "dns.count.auth_rr",
    "dns.resp.name", "dns.resp.type", "dns.resp.ttl",
    "dns.a", "dns.aaaa", "dns.ns",
    "dns.soa.mname", "dns.soa.rname", "dns.soa.serial_number",
    "dns.soa.refresh_interval", "dns.soa.retry_interval",
    "dns.soa.expire_limit", "dns.soa.minimum_ttl",
]

comando = ["tshark", "-r", str(archivo), "-Y", "dns.flags.response == 1", "-T", "fields"]
for c in campos:
    comando += ["-e", c]
comando += ["-E", "occurrence=a", "-E", "aggregator=|"]

res = subprocess.run(comando, capture_output=True, text=True)
if res.returncode != 0:
    print("tshark falló:\n", res.stderr)
    sys.exit(1)

tipos = {"1": "A", "2": "NS", "5": "CNAME", "6": "SOA", "28": "AAAA",
         "43": "DS", "46": "RRSIG", "47": "NSEC", "48": "DNSKEY", "50": "NSEC3"}


def lista(x):
    return x.split("|") if x else []


registros = []
for linea in res.stdout.splitlines():
    cols = linea.split("\t")
    cols += [""] * (len(campos) - len(cols))
    f = dict(zip(campos, cols))

    nombres = lista(f["dns.resp.name"])
    tipos_rr = lista(f["dns.resp.type"])
    ttls = lista(f["dns.resp.ttl"])
    n_an = int(f["dns.count.answers"] or 0)
    n_au = int(f["dns.count.auth_rr"] or 0)

    datos = {
        "1": lista(f["dns.a"]),
        "28": lista(f["dns.aaaa"]),
        "2": lista(f["dns.ns"]),
    }
    soa = list(zip(
        lista(f["dns.soa.mname"]), lista(f["dns.soa.rname"]),
        lista(f["dns.soa.serial_number"]), lista(f["dns.soa.refresh_interval"]),
        lista(f["dns.soa.retry_interval"]), lista(f["dns.soa.expire_limit"]),
        lista(f["dns.soa.minimum_ttl"]),
    ))
    usados = {"1": 0, "28": 0, "2": 0, "6": 0}

    for i, (nombre, tipo) in enumerate(zip(nombres, tipos_rr)):
        if tipo == "41":          # OPT, no es un registro de datos
            continue
        ttl = ttls[i] if i < len(ttls) else ""
        if i < n_an:
            seccion = "Answer"
        elif i < n_an + n_au:
            seccion = "Authority"
        else:
            seccion = "Additional"

        dato = ""
        if tipo in datos and usados[tipo] < len(datos[tipo]):
            dato = datos[tipo][usados[tipo]]
            usados[tipo] += 1
        elif tipo == "6" and usados["6"] < len(soa):
            dato = " ".join(soa[usados["6"]])
            usados["6"] += 1

        registros.append([
            f["frame.number"], f["ip.src"], f["dns.qry.name"],
            "1" if f["dns.flags.authoritative"] in ("1", "True") else "0",
            "1" if f["dns.flags.recavail"] in ("1", "True") else "0",
            seccion, nombre, tipos.get(tipo, tipo), ttl, dato,
        ])

with open(salida, "w", newline="", encoding="utf-8") as fh:
    w = csv.writer(fh)
    w.writerow(["Paquete", "Origen", "Consulta", "AA", "RA",
                "Seccion", "Registro", "Tipo", "TTL_segundos", "Datos"])
    w.writerows(registros)

print("Registros extraidos:", len(registros))
print("Archivo generado:", salida)
for r in registros:
    print(" | ".join(r))

```

The type column of the rows that belong to responses with `NSEC3` records (packet 28 of `captura_dnssec_kali.csv`) is misaligned with the record names, so those records were read directly from Wireshark and `dig` (@tab:dnssec-b).

= Declaration of AI Use

The members of the team used Claude (Anthropic) @claude during this activity [Sonnet 5.5 accessed through claude.ai, November 2026]. This is how we, members used it:

- *Document structure in Typst.* It helped us build the skeleton of the report (template, section layout, tables, figure references) and fix compilation errors. The content of each section comes from our own runs and results.
- *Understanding results.* It explained what certain numbers and outputs meant (for example TTL values, SOA fields, header flags and DNSSEC records), so that we could interpret our own captures.
- *Wording.* It helped us improve the grammar and clarity of our English.
- *Learning the terminal.* It helped us learn how to use the tools of the lab (BIND, `dig`, TShark) from the command line.
- *Final review.* Before delivering, we asked it to look for inconsistencies and missing items in the draft. It suggested corrections and we decided which ones to apply.

The lab itself was built and run by us on our own machines. The configuration, the commands, the traffic captures, the screenshots and the data in the tables come from our executions. We checked the explanations we received against our own captures and the cited documentation. Lastly, AI also helped with double-checking the Python scripts, to make them functional.


= Individual conclusions and CRediTs

== Angel Eduardo Luna

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


=== CRediT
#figure(
  tabla(
    columns: (0.28fr, 0.72fr),
    hd[CRediT role],
    hd[Contribution],
    [Methodology],
    [Designed the structure of the report and of its revision: the audit of the first version, the feedback-to-fix traceability and the verification checklist.],
    [Writing – original draft],
    [Wrote the draft text of the report.],
    [Writing – review and editing],
    [Reviewed and edited the team's contributions, and reviewed the pull requests for the second version.],
    [Supervision],
    [Coordinated the team's work and the review of each member's changes.],
    [Project administration],
    [Set up and maintained the team repository, its branch rules, the modular templates and the build tooling, and assigned the team's tasks and deadlines.],
  ),
  caption: [My CRediT roles and the concrete contribution behind each one.],
) <tab:credit>


== Jannette Cristina Flores Rodríguez
In this activity I worked on part of the lab execution and on the interpretation of what we obtained. I ran some of the commands in the terminal together with a teammate, and then I read the outputs carefully and turned them into tables and text for the report. In practice, I acted on the lab and then analyzed what that action produced.

Among other things, I learned how a recursive server walks the tree from the root and how glue records work; how the TTL decreases when an answer comes from the cache (for example, from 86400 s to 83425 s in our capture); the difference between a resolver that validates DNSSEC and one that does not; and why a result can differ between two networks. I also learned to interpret the results of queries for A, AAAA, SOA, NS, DNSKEY, DS, RRSIG and NSEC3 records.

It was difficult for me to understand the DNSSEC results and the difference in responses between networks, as well as some of the command-line syntax we needed to use. It was also a great exercise to learn not to claim more than the evidence supports.

Personally, I know I can improve in many aspects. For example, I could start working earlier with my team, take the captures with more anticipation, document each run with timestamps, or split the work more evenly from the beginning. None of us anticipated the unexpected circumstances of the last days; starting to work on this paper a few days prior would have been really convenient.

= Contribution (CRediT)

#table(
  columns: (auto, 1fr),
  stroke: none,
  inset: (x: 5pt, y: 4pt),
  align: left + horizon,
  table.hline(),
  [*CRediT role*], [*What I did*],
  table.hline(stroke: 0.5pt),
  [Investigation],
  [Ran part of the laboratory commands in the terminal (together with a teammate) and collected the outputs. Examples: `dig` queries, captures, `named-check`.],
  [Formal analysis],
  [Analyzed the outputs of our runs. Examples: TTLs, flags, SOA values, differences between 8.8.8.8 and the local resolver.],
  [Visualization],
  [Built some of the tables that summarize the results from the terminal outputs.],
  [Writing – original draft],
  [Wrote general text that describes and interprets the results of our runs.],
  [Writing – review & editing],
  [Reviewed the complete technical report, to check for inconsistencies],
  table.hline(),
)

== Montserrat Rodriguez

Throughout this activity, I was able to better understand how DNS works beyond the theoretical concepts we studied in class. My main responsibility was setting up the laboratory in Kali Linux, where I installed BIND and configured four DNS servers: root, unsigned, alpha, and recursive. One of the biggest challenges I faced was dealing with configuration errors, permissions, and technical problems with Wireshark. However, by troubleshooting these issues, I learned how to use different Linux commands and tools to verify that the servers were communicating correctly. I also used TShark and Python to capture and analyze DNS traffic, which helped me understand how DNS records and TTL values behave, especially when information is stored in the recursive server's cache. Another important part was comparing DNSSEC queries using Google DNS and our local recursive server, which showed me how different DNS configurations can affect the responses we receive. Overall, this activity helped me improve my technical skills, problem-solving abilities, and confidence when working with Linux. It also showed me the importance of testing and documenting each step instead of assuming that a configuration works correctly.

== CRediT Contribution

*Methodology:* Adapted and implemented the DNS laboratory environment using Kali Linux and loopback interfaces.

*Software:* Installed and configured BIND, created the DNS configuration and zone files, and developed and executed a Python script to extract DNS records and TTL values.

*Investigation:* Performed DNS and DNSSEC queries using dig, explored the differences between authoritative and recursive servers, and investigated configuration and permission issues.

*Validation:* Verified the configuration and functionality of the four DNS servers using named-checkconf, named-checkzone, and dig.

*Formal Analysis:* Analyzed DNS responses, record types, TTL behavior, caching, and differences between Google DNS and the local recursive server.

*Data Curation:* Captured, organized, and processed DNS traffic using TShark, generating PCAPNG and CSV files as evidence for the technical report.


== Elias Alejandro
=== CRediT


== Carolina Sarahí Sánchez
In this activity I understood that DNS is a chain of delegations and not a single lookup. Each server only knows the next link, and flags such as `aa` and `ra` show who is answering with authority and who is answering from a cache. The TTL also became concrete for me. Seeing a value like 86400 s drop to 83425 s, and matching that difference with the minutes between two queries, showed that caching follows rules that can be checked against the clock.

In the first report I worked on the theory and on checking our statements against the captures. One of them, that `root.hints` is required, turned out to be wrong, and I only fixed it after finding a source that said otherwise. That taught me to check what I write, including what an AI tool suggests, before I trust it. The DNSSEC results also showed me that a signed zone can look unsigned if the signatures do not reach the resolver, so it is better to read the trace carefully before drawing a conclusion.
=== CRediT

#figure(
  table(
    columns: (4.2cm, 1fr),
    align: (left + top, left + top),
    stroke: none,
    table.hline(),
    [*CRediT role*], [*Contribution*],
    table.hline(stroke: 0.5pt),
    [Writing – original draft],
    [Wrote the theory sections of the first report (what BIND is, how authoritative and recursive servers are configured, `root.hints`, the sections of a DNS response and the TTL) and put together its references.],
    [Validation],
    [Checked the values of the first report against our screenshots and the cited sources before delivery, including the TTL arithmetic, the header flags and the `root.hints` claim, which I checked against an ISC source.],
    [Writing – review and editing],
    [Found statements in the first report that our captures did not support, such as where the A and AAAA TTLs came from, and rewrote them with the evidence we had.],
    table.hline(),
  ),
  caption: [My CRediT roles and the concrete contribution behind each one.],
)


#bibliography(
  bytes(
    "
bind920notes:
  type: web
  title: BIND 9.20 Release Notes
  url: https://ftp.arnes.si/pub/packages/bind9/9.20.0/doc/arm/html/notes.html
claude:
  type: web
  title: Claude (large language model)
  author: Anthropic
  url: https://claude.ai
  date: 2026
iscchanges:
  type: web
  title: BIND 9.20 Significant Changes (ISC Knowledge Base)
  url: https://kb.isc.org/docs/bind-920-changes
bindarm:
  type: web
  title: BIND 9 Administrator Reference Manual
  url: https://bind9.readthedocs.io/
rfc1912:
  type: web
  title: 'RFC 1912, Common DNS Operational and Configuration Errors'
  url: https://datatracker.ietf.org/doc/rfc1912/
ripe203:
  type: web
  title: RIPE-203, Recommended SOA values
  url: https://www.ripe.net/publications/docs/ripe-203
",
  ),
  title: "References",
  style: "ieee",
)

