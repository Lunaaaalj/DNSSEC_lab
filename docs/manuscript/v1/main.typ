// ============================================================
//  Technical report (draft) — DNS with BIND, root hints, Wireshark and dig
//  Compile with: typst compile report_dns_bind.typ
// ============================================================

// ---------- Team data (edit) ----------
#let title = "DNS Servers with BIND: Authoritative and Recursive Configuration, Root Hints, and Traffic Analysis"
#let course = "Applications of Cryptography and Cybersecurity"
#let institution = "Tecnológico de Monterrey, Monterrey Campus"
#let team = "Team 1"
#let members = (
  ("", ""),
  ("Elías Alejandro Corral Rodríguez", "A01743624"),
  ("Jannette Cristina Flores Rodríguez", "A01255711"),
  ("Angel Eduardo Luna", "A00842657"),
  ("Montserrat Rodríguez Ramírez", "A01661271"),
  ("Carolina Sarahí Sánchez Meneses", "A00227980"),
)
#let professor = [Mohd Anas Wajid]
#let date = datetime.today().display("[month repr:long] [day], [year]")

// ---------- Global setup ----------
#set document(title: title, author: members.map(m => m.at(0)))
#set page(
  paper: "us-letter",
  margin: (x: 2.5cm, y: 2.5cm),
  numbering: "1",
  header: context {
    if counter(page).get().first() > 1 [
      #set text(size: 9pt, fill: luma(100))
      #team #h(1fr) Technical report
      #line(length: 100%, stroke: 0.5pt + luma(180))
    ]
  },
  columns: 1,
)
#set text(font: "New Computer Modern", size: 11pt, lang: "en")
#set par(justify: true, leading: 0.65em, first-line-indent: 0pt)
#set heading(numbering: "1.1.")
#show heading: set block(above: 1.4em, below: 0.8em)
#show raw.where(block: true): it => block(
  fill: luma(245),
  stroke: 0.5pt + luma(200),
  radius: 3pt,
  inset: 8pt,
  width: 100%,
  it,
)
#show raw: set text(font: "DejaVu Sans Mono", size: 8.5pt)
#set figure(placement: none)
#show figure.caption: set text(size: 9.5pt)
#show link: set text(fill: rgb("#1a56a0"))
#set table(stroke: 0.5pt + luma(150), inset: 6pt)
#show table.cell.where(y: 0): set text(weight: "bold")

// ---------- Helpers ----------
// Pending-item marker (visible in the draft)
#let todo(body) = text(fill: rgb("#b00020"), weight: "bold")[\[TO DO: #body\]]

// Callout box for team notes
#let note(body) = block(
  fill: rgb("#fff8e1"),
  stroke: (left: 3pt + rgb("#f9a825")),
  inset: 8pt,
  width: 100%,
  body,
)

// Placeholder for Wireshark / terminal screenshots.
// To use a real image: capture("description", path: "captures/file.png")
#let capture(description, path: none, width: 90%) = {
  if path != none {
    image(path, width: width)
  } else {
    rect(width: 100%, height: 4.5cm, fill: luma(240), stroke: (
      dash: "dashed",
      paint: luma(150),
    ))[
      #align(center + horizon)[
        #text(fill: luma(100), style: "italic")[Insert screenshot: #description]
      ]
    ]
  }
}

// ============================================================
//  COVER PAGE
// ============================================================
#page(numbering: none, header: none)[
  #align(center)[
    #v(1.5cm)
    #text(size: 13pt)[#institution]
    #v(0.3cm)
    #text(size: 11pt)[#course]
    #v(2.5cm)
    #line(length: 70%, stroke: 1pt)
    #v(0.5cm)
    #text(size: 18pt, weight: "bold")[#title]
    #v(0.5cm)
    #line(length: 70%, stroke: 1pt)
    #v(1.5cm)
    #align(center)[
      #block(width: 80%)[
        #set text(size: 0.9em, hyphenate: false)
        *Abstract* —
        The goal of this activity is to study how DNS servers are configured with BIND, to distinguish authoritative from recursive servers, to understand the role of `root.hints`, and to analyze the structure of DNS responses with Wireshark and `dig`. The BIND and `root.hints` sections are theoretical, while the traffic analysis was carried out in practice on a real domain. This work is the foundation for a later lab in which DNSSEC will be implemented.        #v(1em)
        *Keywords:* DNS, BIND, Wireshark, dig, DNSSEC
      ]
    ]
    #text(size: 13pt, weight: "bold")[#team]
    #v(0.1cm)
    #table(
      columns: (auto, auto),
      stroke: none,
      align: (left, left),
      inset: 4pt,
      ..members.map(m => (m.at(0), m.at(1))).flatten(),
    )
    #v(1.5cm)
    Professors: #professor \
    Date: #date
    #v(1fr)

  ]
]
// ============================================================
//  TABLE OF CONTENTS
// ============================================================
#outline(title: "Contents", indent: auto, depth: 3)
#pagebreak()



// ============================================================
//  INTRODUCTION
// ============================================================
= Introduction

The Domain Name System (DNS) is a distributed, hierarchical system that maps domain names to IP addresses @rfc1034. Thanks to it, users only need to remember a name (for example, `tec.mx`) instead of a numeric address, much like contacts on a phone replaced memorizing phone numbers. Its predecessor was the `hosts.txt` file, a central list of name-to-address mappings that stopped being viable as the network grew, because it did not scale and was hard to keep up to date @rfc1034.

When a user types a name in the browser, a recursive resolver queries the DNS hierarchy (the root server, the top-level domain (TLD) server, and the domain's authoritative server) and returns the IP address. The answer is stored in a cache for a period called the TTL (_Time to Live_), so later queries are answered faster and with less load on the servers @rfc1034.

The goal of this activity is to learn how DNS is configured in a test lab using BIND, to distinguish authoritative from recursive servers, to understand the role of `root.hints`, and to analyze the structure of DNS responses with Wireshark and `dig`. This work is the foundation for a later lab in which DNSSEC will be implemented.


== Objectives

- Describe how BIND is configured as an _authoritative_ and as a _recursive_ server, and which configuration files are involved.
- Explain the role of the `root.hints` file in recursive resolution.
- Analyze DNS responses with Wireshark and `dig` (message sections and SOA, NS, A, and AAAA records, including their TTL).

== Environment used for the traffic analysis,

#figure(
  table(
    columns: (auto, 1fr),
    align: (left, left),
    [Component], [Details],
    [Operating system], [MacOS 15.6.1 (24G90)],
    [`dig` version], [dig 9.10.6],
    [Wireshark version], [Version 4.6.9 (v4.6.9-0-g2d548b197c75).],
    [Topology / IP addresses],
    [Client: MacOS laptop (10.23.76.254) connected through Wi-Fi (`en0`). Recursive resolver: the network's default resolver (10.23.56.43, port 53). Authoritative servers of `typst.app`: `ns.inwx.de.` (192.174.68.104), `ns2.inwx.de.` and `ns3.inwx.eu.`, reached by the resolver on the client's behalf.],
  ),
  caption: [Summary of the environment used for the traffic analysis.],
)

// ============================================================
//  1. BIND
// ============================================================
= What Is BIND and How Is It Used in DNS?

== Overview

BIND (_Berkeley Internet Name Domain_) is the most widely used DNS server software on the Internet. It originated at the University of California, Berkeley in the 1980s and is now developed and maintained by the Internet Systems Consortium (ISC). The current major version is BIND 9, and its main service runs as the `named` process @isc_bind9_arm.

BIND implements the standard DNS protocols and is used both to publish information about a network's own domains and to resolve names on behalf of its clients. It also ships with supporting tools: `dig` (queries), `rndc` (service control), `named-checkconf` and `named-checkzone` (configuration and zone validation), and utilities for DNSSEC @isc_bind9_arm.

== Main functions

#figure(
  table(
    columns: (auto, 1fr),
    align: (left, left),
    [Function], [Description],
    [Authoritative server],
    [Stores the records of the zones it manages and answers with authority for them (responses carry the `aa` flag).],

    [Recursive server (resolver)],
    [Resolves client queries by walking the DNS hierarchy (root, TLD, authoritative) and returns the final answer.],

    [Cache],
    [Stores answers for their TTL so repeated queries are answered faster.],

    [Others (forwarding, views, DNSSEC, zone transfers)],
    [_Forwarding_: pass queries on to another resolver. Views: answer differently depending on the client. DNSSEC: sign and validate responses. Zone transfers: copy zones between a primary and secondary servers.],
  ),
  caption: [BIND functions in a DNS environment.],
)

// ============================================================
//  2. CONFIGURATION
// ============================================================
= BIND Configuration Options

== Configuration files involved

On Debian, Ubuntu, and Kali the BIND configuration is split into several files inside `/etc/bind/`; on RHEL-type systems everything is usually kept in `/etc/named.conf`. The table shows which file controls each part of the server @isc_bind9_arm.

#figure(
  {
    set par(justify: false)
    table(
      columns: (3.9cm, 5.9cm, 1fr),
      align: (left + top, left + top, left + top),
      [*File*], [*Typical location*], [*Purpose*],
      [`named.conf`],
      [`/etc/bind/named.conf` \ (RHEL: `/etc/named.conf`)],
      [Main file. On Debian-style systems it only includes the other files; on RHEL-type systems it holds the whole configuration.],

      [`named.conf.options`],
      [`/etc/bind/named.conf.options`],
      [Global options (`directory`, `recursion`, `allow-query`, `forwarders`, `dnssec-validation`). The *recursive* mode is configured here.],

      [`named.conf.local`],
      [`/etc/bind/named.conf.local`],
      [Declaration of the zones the server owns (primary/secondary). The *authoritative* mode is configured here.],

      [Zone file (`db.example.com`)],
      [`/etc/bind/db.example.com` \ (RHEL: `/var/named/`)],
      [The records of the zone: SOA, NS, A, AAAA, etc.],

      [`root.hints`],
      [`/usr/share/dns/root.hints` \ (or the file named in the `"."` zone)],
      [List of root servers used to start a resolution. BIND has a built-in copy if the file is not declared @isc_bindusers_2009.],
    )
  },
  caption: [Relevant BIND configuration files.],
)

== Authoritative server

An authoritative server holds the original data for one or more zones. To configure it, each zone is declared in `named.conf.local` with `type master` (or `primary` in recent versions) and the path of its zone file. The `allow-transfer` option restricts who may copy the zone. A server that is only authoritative should disable recursion with the option `recursion no`, because it should not resolve names for third parties, and leaving recursion on exposes it to abuse (open resolver) @isc_bind9_arm.

#block(breakable: false)[
  ```
  // named.conf.local  (example)
  zone "example.com" {
      type master;
      file "/etc/bind/db.example.com";
      allow-transfer { none; };
  };
  ```
]

#block(breakable: false)[
  ```
  // named.conf.options  (authoritative-ONLY server)
  options {
      directory "/var/cache/bind";
      recursion no;
      allow-query { any; };
  };
  ```
]

#block(breakable: false)[
  ```
  ; db.example.com - zone file (example)
  $TTL 3600
  @   IN  SOA ns1.example.com. admin.example.com. (
              2026110601 ; serial
              3600       ; refresh
              900        ; retry
              604800     ; expire
              300 )      ; negative TTL
  @       IN  NS    ns1.example.com.
  ns1     IN  A     192.168.1.10
  www     IN  A     192.168.1.20
  www     IN  AAAA  2001:db8::20
  ```
]

The fields of the SOA record are:

#figure(
  {
    set par(justify: false)
    table(
      columns: (3.4cm, 1fr),
      align: (left + top, left + top),
      [*Field*], [*Meaning*],
      [Primary server], [`ns1.example.com.`, the main name server of the zone.],
      [Responsible email],
      [`admin.example.com.` (the first dot stands for the at-sign).],

      [Serial],
      [Version number of the zone; it must increase with every change.],

      [Refresh], [How often the secondary servers check for changes.],
      [Retry], [How often they retry if the check fails.],
      [Expire], [When they stop answering if they cannot reach the primary.],
      [Negative TTL],
      [How long the fact that a name does not exist is cached @rfc2308.],
    )
  },
  caption: [Fields of the SOA record.],
)

== Recursive server

A recursive server receives client queries and resolves them on their behalf. It is configured in `named.conf.options` with the option `recursion yes`. The options `allow-recursion` and `allow-query-cache` limit who may use it, so only the clients of its own network can. Optionally, `forwarders` hand resolution over to another server, and `dnssec-validation` enables DNSSEC signature validation @isc_bind9_arm. This type of server needs a list of root servers to know where to start: BIND's built-in list, or a `root.hints` file declared explicitly @isc_bindusers_2009.

#block(breakable: false)[
  ```
  // named.conf.options  (recursive server)
  options {
      directory "/var/cache/bind";
      recursion yes;
      allow-recursion { 192.168.1.0/24; localhost; };
      listen-on { any; };
      // forwarders { 8.8.8.8; };   // optional
      dnssec-validation auto;
  };
  ```
]

`allow-recursion` is restricted because a recursive resolver open to the whole Internet can be abused by attackers for amplification (DDoS) attacks and as a target for cache poisoning attempts.

== Authoritative vs. recursive comparison

#figure(
  {
    set par(justify: false)
    table(
      columns: (3.9cm, 1fr, 1fr),
      align: (left + top, left + top, left + top),
      [*Aspect*], [*Authoritative*], [*Recursive*],
      [`recursion`], [`no`], [`yes`],
      [Own zones],
      [Yes, declared with `zone` and a zone file],
      [Not necessarily],

      [Needs `root.hints`],
      [No],
      [Not strictly (a built-in copy is used if none is declared)],

      [Typical response flag],
      [`aa` (authoritative answer)],
      [`ra` (recursion available)],

      [Files to modify],
      [`named.conf.local` and the zone file (plus `named.conf.options` to set `recursion no`)],
      [`named.conf.options`],
    )
  },
  caption: [Configuration differences between the two modes.],
)

== Configuration verification

#block(breakable: false)[
  ```
  named-checkconf                              # validates named.conf
  named-checkzone example.com /etc/bind/db.example.com
  sudo systemctl restart named                 # or bind9, depending on the distro
  sudo systemctl status named
  ```
]

// ============================================================
//  3. ROOT HINTS
// ============================================================
= Importance of the `root.hints` File

A recursive resolver starts with an empty cache and does not know any DNS server, so it needs a list of root servers to know where to begin any resolution. BIND includes a built-in list, and `root.hints` is the way to declare that list explicitly. In BIND it is declared as a root zone of type `hint` @isc_bind9_arm:

#block(breakable: false)[
  ```
  zone "." {
      type hint;
      file "/usr/share/dns/root.hints";
  };
  ```
]

== Role in iterative resolution

When a recursive resolver has no cached answer, it resolves a name step by step, and `root.hints` provides the first step:

+ The resolver asks a root server (taken from `root.hints`), which answers with the servers of the TLD (for example `.mx`).
+ The resolver asks the TLD server, which answers with the authoritative servers of the domain.
+ The resolver asks the authoritative server, which gives the final answer.
+ The resolver returns the answer to the client and stores it in its cache for the TTL.

BIND ships with a built-in copy, so `root.hints` is not strictly required, but declaring it explicitly allows the list to be updated or replaced, which is essential in an isolated network (for example, a private test lab) where the real root servers are unreachable and the file must point to that network's own root servers. If the declared file is missing, empty, or lists unreachable servers, the resolver may not be able to start the resolution chain and BIND reports errors. Root server addresses change very rarely, but the file should still be kept up to date. An up-to-date copy is published by IANA @iana_root_files and can also be obtained with:

#block(breakable: false)[
  ```
  # Obtain an up-to-date copy of the file
  dig +bufsize=1200 +norec NS . @a.root-servers.net > root.hints
  ```
]



// ============================================================
//  4. WIRESHARK + DIG
// ============================================================
= DNS Query Analysis with Wireshark and `dig`

== Methodology

The analysis was carried out against a real domain, `typst.app`, through the network's recursive resolver, to observe the structure of real DNS traffic.

- Domain queried: `typst.app`
- DNS server queried: the network's recursive resolver (10.23.56.43), which is the default resolver of the client; `dig` was run without specifying a server (`@server`).
- Client: macOS laptop (10.23.76.254) with `dig` 9.10.6.
- Wireshark capture interface: Wi-Fi (`en0`). Display filter: `dns.qry.name == "typst.app"`.

```bash
dig typst.app SOA
dig typst.app NS
dig typst.app A
dig typst.app AAAA
```

#figure(
  image("../figures/real dig typst.png"),
  caption: [DNS packets for `typst.app` captured on Wi-Fi (`en0`) with the filter `dns.qry.name == "typst.app"`. The last eight packets correspond to the four `dig` queries and their responses.],
)


== Sections of a DNS response message

A DNS response message has four sections @rfc1035.

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    align: (left, left, left),
    [Section], [Description], [Observed in the capture],
    [Question],
    [Repeats the original DNS query made, confirms the parameters.],
    [
      `typst.app. IN NS`: name `typst.app`, type NS, class IN (`Questions: 1`).
    ],

    [Answer],
    [Contains the DNS resource records that match the lookup request.],
    [
      Three NS records (`Answer RRs: 3`), all with TTL 4076 s (1 h 7 min 56 s): \
      `ns.inwx.de.`, `ns2.inwx.de.`, `ns3.inwx.eu.`
    ],

    [Authority],
    [Lists the name servers that are authoritative for the zone or to which the query is delegated; empty when the answer is complete.],
    [
      Empty (`Authority RRs: 0`).
    ],

    [Additional],
    [Auxiliary resource records that were not explicitly requested but help the client avoid extra queries.],
    [
      Three records (`Additional RRs: 3`): an A record (`ns.inwx.de.` → 192.174.68.104), an AAAA record (`ns.inwx.de.` → 2001:67c:1bc::104), and the EDNS OPT pseudo-record. The two address records have TTL 291 s. \
    ],
  ),
  caption: [Sections of the DNS response message.],
)

The response header (flags `0x8180`) has the QR, RD, and RA bits set and the AA bit clear @rfc1035. This means the answer came from a recursive resolver (10.23.56.43) and not directly from an authoritative server of `typst.app`, which is consistent with the `ra` flag discussed in Section 3. The TTL of 4076 s is most likely the remaining time of a cached copy, not the value configured in the zone. The Authority section is empty because the response already contains the requested records and no referral to another server is needed, while the Additional section carries the addresses of `ns.inwx.de` so the client can contact it without a new query.

#figure(
  image("../figures/5.2.png"),
  caption: [DNS response packet with its four sections.],
)

== SOA records

The SOA (_Start of Authority_) record marks the start of a zone and holds its administrative parameters; each zone has exactly one @rfc1035. The query `dig typst.app SOA` returned one SOA record in the Answer section (`ANSWER: 1`), whose fields are summarized below.

#figure(
  table(
    columns: (auto, auto, 1fr),
    align: (left, left, left),
    [Field], [Value], [Meaning],
    [Primary server (MNAME)], [`ns.inwx.de.`], [Main name server of the zone.],
    [Responsible party (RNAME)],
    [`hostmaster.inwx.de.`],
    [Contact email, read as `hostmaster@inwx.de` (the first dot stands for the at-sign).],

    [Serial],
    [`2026101700`],
    [Zone version. It follows the `YYYYMMDDnn` convention: October 17, 2026, revision 00.],

    [Refresh],
    [10800 s (3 h)],
    [How often secondary servers check the primary for changes.],

    [Retry], [3600 s (1 h)], [How often they retry if the check fails.],
    [Expire],
    [604800 s (7 days)],
    [When secondary servers stop answering if they cannot reach the primary.],

    [Minimum / negative TTL],
    [3600 s (1 h)],
    [How long the non-existence of a name may be cached @rfc2308.],
  ),
  caption: [Fields of the SOA record of `typst.app`.],
)

The record itself has a TTL of 86400 s (24 hours), which is different from the _minimum_ field (3600 s): the first controls how long the SOA record can be cached, while the second applies to negative answers. The Additional section of this response carried the A and AAAA records of the primary server `ns.inwx.de.` (TTL 300 s), so the client can reach it without another query. The response was slower (198 ms) than the other queries (about 20 ms), which suggests that the resolver had to fetch it from the authoritative server instead of its cache.

#figure(
  image("../figures/soa dig.png", width: 100%),
  caption: [SOA record query and response in Terminal.],
)
#figure(
  image("../figures/soa wireshark.png"),
  caption: [SOA record query and response in Wireshark.],
)

== NS records

An NS record names a server that is authoritative for a domain, and it is the mechanism of DNS delegation: the NS records of a zone, published in the parent zone and in the zone itself, tell resolvers which servers to ask for that zone's data @rfc1034. The query for `typst.app` returned three NS records (`Answer RRs: 3`), `ns.inwx.de.`, `ns2.inwx.de.`, and `ns3.inwx.eu.`, all with a TTL of 4076 s (1 hour, 7 minutes, 56 seconds). Having several name servers, in different domains (`.de` and `.eu`), provides redundancy: if one fails, the zone can still be resolved through the others.

The response was marked with the `rd` and `ra` flags and without `aa`, so it was delivered by the network's recursive resolver (10.23.56.43) and not directly by an authoritative server. The Authority section is empty (`Authority RRs: 0`) because the answer is already complete. The Additional section carried the A (192.174.68.104) and AAAA (2001:67c:1bc::104) records of `ns.inwx.de.`, both with TTL 291 s, plus the EDNS OPT pseudo-record. The TTL of 4076 s is not a round number, which indicates that it is the remaining time of a cached copy.

#figure(
  image("../figures/ns dig.png", width: 80%),
  caption: [NS record query and response in Terminal.],
)
#figure(
  image("../figures/ns wireshark.png"),
  caption: [NS record query and response in Wireshark.],
)

== A records

An A record maps a name to an IPv4 address (32 bits) @rfc1035. The query `dig typst.app A` returned a single A record (`Answer RRs: 1`): `typst.app` resolves to `150.171.109.104`, with a TTL of 300 s (5 minutes). The response has `Authority RRs: 0`, and its only Additional record is the EDNS OPT pseudo-record. In that record, the DO bit is 0, which means the client did not request DNSSEC data, something that will change in the next lab. As in the previous queries, the `aa` flag is not set and `ra` is set, so the answer came from the recursive resolver. The query took about 20 ms.

#figure(
  image("../figures/a dig.png", width: 61%),
  caption: [A record query and response in Terminal.],
)
#figure(
  image("../figures/a wireshark.png", width: 95%),
  caption: [A record query and response in Wireshark.],
)

== AAAA records

An AAAA record maps a name to an IPv6 address (128 bits), and it plays the same role for IPv6 that the A record plays for IPv4. The query `dig typst.app AAAA` returned a single record (`Answer RRs: 1`): `typst.app` resolves to `2603:1061:14:62::1`, with a TTL of 300 s (5 minutes), the same as its A record. The structure of the response is the same as for the A query: no Authority records, the OPT pseudo-record as the only Additional record, and the `ra` flag set. The fact that the domain has both A and AAAA records means that it can be reached from IPv4 and IPv6 networks (dual stack).

#figure(
  image("../figures/aaaa dig.png", width: 70%),
  caption: [AAAA record query and response in Terminal.],
)
#figure(
  image("../figures/aaaa wireshark.png"),
  caption: [AAAA record query and response in Wireshark.],
)

== TTL summary by record

The TTL (_Time to Live_) indicates how many seconds a record may be cached before it must be queried again @rfc1034.

#figure(
  table(
    columns: (auto, auto, auto, 1fr),
    align: (left, left, right, left),
    [Type], [Name], [TTL (s)], [Value / Notes],
    [SOA],
    [`typst.app.`],
    [86400],
    [`ns.inwx.de.` `hostmaster.inwx.de.`, serial 2026101700, minimum 3600 s],

    [NS],
    [`typst.app.`],
    [4076],
    [`ns.inwx.de.`, `ns2.inwx.de.`, `ns3.inwx.eu.`],

    [A], [`typst.app.`], [300], [`150.171.109.104`],
    [AAAA], [`typst.app.`], [300], [`2603:1061:14:62::1`],
    [A (additional)],
    [`ns.inwx.de.`],
    [300 / 291],
    [`192.174.68.104`. 300 s in the SOA response, 291 s in the NS response],

    [AAAA (additional)],
    [`ns.inwx.de.`],
    [300 / 291],
    [`2001:67c:1bc::104`. Same behavior as the A record above],
  ),
  caption: [Observed TTL for each record type in the domain `typst.app`.],
)

The TTLs fall into two groups. The SOA (86400 s), A (300 s), and AAAA (300 s) records have round values, which is consistent with the TTLs configured in the zone. In contrast, the NS records show 4076 s, which is not a round number: it is the remaining time of a copy that was already cached and is counting down.

The captures also show the countdown directly. The A and AAAA records of `ns.inwx.de.` appeared with a TTL of 300 s in the SOA response (frame 22556, `dig` run at 18:22:08) and with 291 s in the NS response (frame 23600, `dig` run at 18:22:17). The difference of 9 s matches the time elapsed between both queries (about 9.3 s according to the Wireshark timestamps), which confirms that the resolver was serving a cached copy whose TTL decreased with time. When it reaches zero, the resolver must query the authoritative server again.

The record TTL must not be confused with the _minimum_ field of the SOA record. The first controls how long an existing record can be cached; for example, the SOA record itself has a TTL of 86400 s (24 hours). The second, 3600 s in this zone, is used for negative caching: according to RFC 2308 @rfc2308, the resolver caches the non-existence of a name for the lower of the SOA record's TTL and its minimum field, which here is 3600 s (1 hour).

// ============================================================
//  RESULTS, CONCLUSIONS, REFERENCES
// ============================================================
= Results and Discussion

== Authoritative vs. recursive servers

The study of BIND's configuration shows that the two server roles are separated both by purpose and by the files that define them. An authoritative server is defined in `named.conf.local` (zone declaration) and in the zone file, and it answers only for the zones it owns, which is why its responses carry the `aa` flag; if it is authoritative-only, it also sets `recursion no;` in `named.conf.options`. A recursive server is defined in `named.conf.options` with the option `recursion yes`, and it answers on behalf of its clients by walking the hierarchy and caching the results, so its answers carry the `ra` flag.

The captures of Section 5 show the recursive side. Every response had the `rd` and `ra` flags set and `aa` clear, so it came from the network's recursive resolver (10.23.56.43) and not from an authoritative server of `typst.app`. An `aa` flag would only appear in an answer received directly from one of the domain's name servers, which was not captured in this activity.

A server that is only authoritative should use `recursion no`. A recursive server should limit its clients with `allow-recursion`; otherwise it becomes an open resolver that can be abused for amplification attacks and cache poisoning attempts.

== Effect of `root.hints`

The `root.hints` file provides a recursive resolver, which starts from an empty cache, with the addresses of the root servers (through this file or BIND's built-in copy). The root servers return the referral to the TLD servers, which in turn return the referral to the authoritative servers of the domain. An authoritative-only server does not need it, since it never resolves names for third parties. In an isolated network the file takes on a critical role: the built-in list of BIND points to the real root servers, which would be unreachable, so `root.hints` must point to that network's own root servers. If the file is missing, empty, or lists unreachable servers, the resolution chain may not start and `named` reports errors.

== Analysis of the DNS response

The query for the NS records of `typst.app` returned a response with the four sections of a DNS message, summarized below.

#figure(
  {
    set par(justify: false)
    table(
      columns: (2.3cm, 1.6cm, 1fr),
      align: (left + top, left + top, left + top),
      [*Section*], [*Count*], [*Content observed*],
      [Question], [1], [`typst.app. IN NS`],
      [Answer],
      [3],
      [NS records `ns.inwx.de.`, `ns2.inwx.de.`, and `ns3.inwx.eu.`, all with TTL 4076 s],

      [Authority], [0], [Empty],
      [Additional],
      [3],
      [A (192.174.68.104) and AAAA (2001:67c:1bc::104) records of `ns.inwx.de.` (TTL 291 s) and the EDNS OPT pseudo-record],
    )
  },
  caption: [Summary of the response sections observed in the capture.],
)

The Answer section contains exactly what was asked for, while the Additional section carries data that saves the client an extra query: the IPv4 and IPv6 addresses of `ns.inwx.de.` come attached so that the client can contact that name server right away. The Authority section is empty because the response already contains the requested records and no delegation to another server is needed. The header flags (`qr rd ra`, without `aa`) show that the response came from the network's recursive resolver (10.23.56.43) and not directly from an authoritative server of `typst.app`.

== TTL behavior

The records observed have different TTLs (4076 s for the NS records, 300 s for A and AAAA, and 86400 s for the SOA), which confirms that the TTL is a property of each record set and not of the whole message. The NS value is most likely a remaining time, not the configured one, because it is not a round number and was probably served from the resolver's cache. The captures show the countdown directly: the addresses of `ns.inwx.de.` went from 300 s to 291 s in the 9 seconds between two queries. Once the TTL reaches zero, the resolver must query the authoritative server again. This is the mechanism by which caching reduces the load on the servers and speeds up repeated queries; it also means that a change in a zone can take up to the old TTL to reach every resolver.

The record TTL must not be confused with the _minimum_ field of the SOA record. The first controls how long a record that exists may be cached, while the second (3600 s in `typst.app`) is used for negative caching: according to RFC 2308 @rfc2308, a resolver caches the non-existence of a name for the lower of the SOA record's TTL and its minimum field. Here that is the lower of 86400 s and 3600 s, so a negative answer would be cached for 3600 s (1 hour).


= Conclusions

+ BIND is a flexible DNS server in which the same `named` process can act as an authoritative server, a recursive resolver, or both. The role is defined by a few clearly separated parts of the configuration: the zone declarations (`named.conf.local`) and zone files for the authoritative role, and the `recursion` and `allow-recursion` options (`named.conf.options`) for the recursive role.
+ Separating both roles is a security best practice. An authoritative-only server should use `recursion no`, and a recursive server should restrict its clients with `allow-recursion`, so that neither becomes an open resolver that can be abused for amplification attacks or cache poisoning attempts.
+ The `root.hints` file is the starting point of any recursive resolution. Although BIND includes a built-in copy, declaring it explicitly allows the list to be updated or replaced, which is essential in an isolated network where the real root servers are unreachable.
+ The captures of `typst.app` made with `dig` and Wireshark showed the four sections of a DNS response (Question, Answer, Authority, and Additional). They also showed how the Additional section carries the address records of `ns.inwx.de.` and the EDNS OPT pseudo-record, which saves the client extra queries.
+ The TTL is a property of each record set: 86400 s for the SOA, 4076 s for the NS records, and 300 s for the A and AAAA records. The addresses of `ns.inwx.de.` went from 300 s to 291 s in the 9 seconds between two queries, which showed the cache countdown directly and explains why a change in a zone can take up to the old TTL to reach every resolver.
+ The record TTL and the SOA _minimum_ field (3600 s) control different things: the first applies to records that exist, and the second, according to RFC 2308 @rfc2308, applies to negative caching, that is, to how long the non-existence of a name is remembered.
+ The OPT record showed the DO bit set to 0, meaning that no DNSSEC data was requested. The knowledge gained in this activity (zone files, recursion, root hints, DNS message structure, and TTL behavior) is the foundation for the next lab, in which DNSSEC will be implemented.


= References


#bibliography("../../../bibliography.bib", style: "apa", title: none)


= Declaration of AI Use

We used Claude Sonnet 5.5 @anthropic2026sonnet55 between November 6 and 9, 2026. We used it to:

- *Understand concepts* from class (protocols, ports, DNS records, TTL, DNSSEC).
- *Draft the theory sections* of the report in Typst, which the team then edited and corrected.
- *Review our draft* for technical errors, inconsistencies, and claims our captures did not support.
- *Format* tables, code blocks, and references.

We did not use it to produce data: the `dig` queries and Wireshark captures were done by team members, and all values in Section 5 come from them. We did not accept its output by default; for example, we checked the `root.hints` claim against an ISC source @isc_bindusers_2009 and corrected an early draft. The team is responsible for the content of this report.

