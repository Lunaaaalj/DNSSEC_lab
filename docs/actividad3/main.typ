// ============================================================
//  Technical report — Part 3 (draft)
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
  title: [Signed DNSSEC Tree with BIND: `signed`, `beta` and `gamma` \ #text(size: 13pt, weight: "regular")[Technical report, part 3 (DRAFT).]],
  authors: (
    (name: "Montserrat Rodríguez Ramírez", affiliation: "A01661271"),
    (name: "Jannette Cristina Flores Rodríguez", affiliation: "A01255711"),
    (name: "Angel Eduardo Luna", affiliation: "A00842657"),
    (name: "Carolina Sarahí Sánchez Meneses", affiliation: "A00227980"),
    (name: "Elías Alejandro Corral Rodríguez", affiliation: "A01743624"),
  ),
  professor: strong("Mohd Anas Wajid"),
  institution: "Tecnológico de Monterrey",
  date: "November 22, 2026",
  abstract: [
    We extend the private DNS tree of the previous activity with a signed root, a signed gTLD `signed`, a signed
    child `beta.signed` and an unsigned sibling `gamma.signed`, all on BIND 9.20.30 over loopback addresses. Zones are
    signed with ECDSAP256SHA256 and NSEC3 (no salt, zero extra iterations). A second recursive resolver validates
    DNSSEC with the private root key as trust anchor; the first one does not. With `dig`, `delv` and TShark we show that the
    chain of trust works, that the unsigned `gamma.signed` is accepted as _insecure_ and not as bogus, and that only the validating
    resolver sets the `AD` flag and rejects tampered data (`SERVFAIL`), whereas the other one returns it.
  ],
  keywords: ("DNSSEC", "BIND 9.20", "NSEC3", "chain of trust", "validating resolver"),
)

= Laboratory Changes

== Backup of version 1

Before any change, the tree of Activity 2 was preserved in two ways: the git tag `actividad2-v1` and the directory
`lab/v1/`, which holds the configuration and zone files exactly as printed in the previous report (root, `unsigned`,
`alpha`, `recursive1`). Version 2 lives in `lab/v2/`. The original root zone is also kept as
`lab/v2/root/zones/db.root.orig` (226 bytes) as a comparison point for the signed root.

== New tree

#figure(
  tabla(
    columns: (auto, auto, auto, 1fr),
    hd[Server], hd[Address], hd[Zone], hd[DNSSEC state],
    [root], [`172.30.0.10`], [`.`], [Signed; its KSK is the trust anchor],
    [unsigned], [`172.30.0.20`], [`unsigned.`], [Unsigned (as in Activity 2)],
    [alpha], [`172.30.0.30`], [`alpha.unsigned.`], [Unsigned (as in Activity 2)],
    [signed], [`172.30.0.40`], [`signed.`], [Signed; `DS` published in the root],
    [beta], [`172.30.0.50`], [`beta.signed.`], [Signed; `DS` published in `signed.`; `www` A `172.30.0.50`],
    [gamma], [`172.30.0.60`], [`gamma.signed.`], [Unsigned; no `DS`; `www` A `172.30.0.60`],
    [recursive1], [`172.30.0.100`], [hints], [Does _not_ validate (`dnssec-validation no`)],
    [recursive2], [`172.30.0.200`], [hints], [Validates (`dnssec-validation yes` + trust anchor)],
  ),
  caption: [Servers of version 2. The last two rows are the two recursive resolvers that are compared.],
) <tab:servidores>

`recursive2` is a new instance, not the one from Activity 2. It uses `dnssec-validation yes` and not `auto`: with `auto`
BIND would load the built-in anchor of the public root, which is unrelated to our private root, and every answer would fail.
The anchor is the DS of the root KSK (key tag 8232), generated by the signing script:

```
trust-anchors {
    . static-ds 8232 13 2 "992CFA2F64B30F04...3C6FAB1C";
};
```

= Algorithm and Denial of Existence

We chose *ECDSAP256SHA256 (algorithm 13)* @rfc6605 with *NSEC3* @rfc5155 and the parameters recommended by @rfc9276:
empty salt and zero additional iterations. Reasons:

- Algorithm 13 is the one `starcke.mx` uses in the public Internet (Activity 2), so the lab mirrors what we already observed,
  it is a mandatory-to-implement algorithm in the algorithm requirements of @rfc8624, and its keys and signatures are short (a 64-byte public key), which keeps
  responses small and avoids fragmentation, even if our traffic is on loopback.
- NSEC3 hides the names of the zone (`NSEC3` owner names are hashes, e.g. `BM35LJS4NB2420B8HF5RMBO4QE2QN8TU.beta.signed.`),
  which is closer to how production zones behave, and it lets us show the proof that a delegation has no `DS` (`gamma.signed`).
  The zone has no sensitive names, so this is a learning choice and not a security need.
- DS digests use SHA-256 (digest type 2).

= Signing Procedure

Signing is automated by `lab/scripts/10-sign.sh`, and it must go _bottom-up_, because every parent needs the `DS` of its child
before it can be signed:

```bash
# for each zone (one KSK + one ZSK):
dnssec-keygen -K keys -a ECDSAP256SHA256 -f KSK -n ZONE <zone>
dnssec-keygen -K keys -a ECDSAP256SHA256        -n ZONE <zone>
dnssec-signzone -S -K keys -3 - -H 0 -N unixtime -o <zone> -f db.<zone>.signed db.<zone>.work
dnssec-verify -o <zone> db.<zone>.signed
# order: beta.signed -> (DS into signed) -> signed -> (DS into root) -> root
```

#figure(
  tabla(
    columns: (auto, auto, auto, 1fr),
    hd[Zone], hd[KSK tag], hd[ZSK tag], hd[`DS` published in the parent],
    [`.`], [8232], [1467], [None: it is the trust anchor],
    [`signed.`], [23779], [41363], [`signed. DS 23779 13 2` in the root],
    [`beta.signed.`], [4639], [40382], [`beta.signed. DS 4639 13 2` in `signed.`],
    [`gamma.signed.`], [-], [-], [None (insecure delegation)],
  ),
  caption: [Keys and `DS` records of the signed tree.],
) <tab:claves>

`dnssec-verify` reported every signed zone as fully signed, with one active KSK and one active ZSK. The root went from 226 bytes
(`db.root.orig`) to 3754 bytes (`db.root.signed`), and it now contains `DNSKEY`, `RRSIG`, `NSEC3`, `NSEC3PARAM` and the `DS` for `signed.`.

#captura("img/fig_checkzone.png", [`named-checkzone` on the four zones and `dnssec-verify` on the three signed ones (rendered from `lab/evidence/fig_checkzone.txt`).], "fig:check")

= Validating vs. Non-validating Resolver

Both resolvers were restarted before each run to start with an empty cache, and the same seven queries were issued to each
one while TShark captured port 53 on `lo` (`lab/scripts/40-tests.sh`, output in `lab/evidence/`).

#figure(
  tabla(
    columns: (1.6fr, 1fr, 1fr),
    hd[Query (`+dnssec`)], hd[`recursive2` (`.200`)], hd[`recursive1` (`.100`)],
    [`www.beta.signed A`], [NOERROR, `ad`, RRSIG], [NOERROR, no `ad`, RRSIG],
    [`www.gamma.signed A`], [NOERROR, no `ad`, no RRSIG], [NOERROR, no `ad`, no RRSIG],
    [`www.alpha.unsigned A`], [NOERROR, no `ad`], [NOERROR, no `ad`],
    [`signed DNSKEY`], [NOERROR, `ad`], [NOERROR, no `ad`],
    [`beta.signed DS`], [NOERROR, `ad`], [NOERROR, no `ad`],
    [`nx.beta.signed A`], [NXDOMAIN, `ad`, NSEC3 + RRSIG], [NXDOMAIN, no `ad`, NSEC3 + RRSIG],
    [`gamma.signed DS`], [NOERROR (empty), `ad`, NSEC3 proves no `DS`], [NOERROR (empty), no `ad`, same NSEC3],
  ),
  caption: [Responses of the two resolvers (from `dig_dnssec.txt` and `dig_sin_dnssec.txt`).],
) <tab:comparacion>

Both resolvers return the signatures when the client sets `DO`; what changes is the verdict. Only `recursive2` sets `AD`,
and it does so exactly where a chain of trust exists. `www.gamma.signed` is answered without `AD` and without error: `signed.` proves with
a signed `NSEC3` that `gamma.signed` has no `DS`, so the answer is _insecure_, not _bogus_. The same holds for `unsigned`,
which has no `DS` in the root.

#figure(
  tabla(
    columns: (1.8fr, 1fr, 1fr),
    hd[Measure (same seven queries)], hd[`.200`], hd[`.100`],
    [Packets captured on `lo`], [64], [47],
    [Queries sent to other servers], [22], [15],
    [`DNSKEY` queries], [4], [1],
    [Responses with `AD`], [5], [0],
  ),
  caption: [Traffic of each resolver (`captura_recursivo_dnssec.pcapng` and `captura_recursivo_sin_dnssec.pcapng`).],
) <tab:trafico>

The validating resolver sends more queries because it must fetch and check the keys of every zone on the path (the root, `signed.`
and `beta.signed.`); the `DNSKEY` count (4 vs. 1) shows it. The `NS` queries also differ (12 from `.200`, 8 from `.100`). The queries for `signed`, `beta.signed`, `gamma.signed` and `alpha.unsigned` are the same in both captures (one each); the difference is in the root `NS` set (`.`), queried seven times by `.200` and twice by `.100` (@fig:ns), while `.100` asked for `unsigned` twice and `.200` once. We did not test why the validating resolver refreshes the root `NS` set more often; a possible cause is that it re-primes the root while it fetches keys, but we did not confirm it.

#captura("img/fig_ns.png", [Queries for the root `NS` set sent to the root server by each resolver (`dns.qry.type == 2`).], "fig:ns", w: 100%)

#captura("img/fig_ad.png", [TShark with display filter `dns.flags.authenticated == 1`: five responses with `AD` from `.200` and none from `.100`.], "fig:ad", w: 100%)
#captura("img/fig_dnskey.png", [`DNSKEY` queries sent by each resolver (`dns.qry.type == 48`, client queries excluded): four from `.200`, one from `.100`.], "fig:dnskey", w: 100%)
#captura("img/fig_delv.png", [`delv` through `recursive2` with the private trust anchor: `www.beta.signed` is _fully validated_ and `www.gamma.signed` is an _unsigned answer_.], "fig:delv", w: 85%)

== Tampering test

To see the practical difference, the `A` record of `www.beta.signed` was changed from `172.30.0.50` to `172.30.0.66` in the signed
zone file _without_ re-signing (`lab/scripts/50-bogus.sh`; the file was restored afterwards).

#figure(
  tabla(
    columns: (1.4fr, 1fr, 2fr),
    hd[Query], hd[Result], hd[Meaning],
    [`.200`, `+dnssec`], [`SERVFAIL`], [The `RRSIG` does not match the modified data: the answer is rejected.],
    [`.200`, `+dnssec +cd`], [NOERROR, `cd`, `172.30.0.66`], [Checking disabled: the forged data is returned, without `AD`.],
    [`.100`, `+dnssec`], [NOERROR, `172.30.0.66`], [No validation: the forged data is accepted.],
  ),
  caption: [Behavior with forged data (`dig_bogus.txt`).],
) <tab:bogus>

The capture of this test contains one `SERVFAIL` response. Note that `dig` did not show any Extended DNS Error for this failure
(we looked for it and the output has none), so we only claim the `SERVFAIL`. After restoring the zone, `.200` answered
again with `NOERROR` and `AD`.

= Preliminary Findings and Pending Work

- The chain root $->$ `signed` $->$ `beta` validates; `delv` reports it as fully validated (@fig:delv).
- `gamma.signed` and the Activity 2 subtree are insecure by design, and the validating resolver accepts them without `AD`.
- The only observable differences between the resolvers are the `AD` flag, extra key-fetching traffic and the behavior under bogus data.
- The figures are terminal renderings of real command output (TShark, `delv`, BIND tools), produced by `lab/scripts/70-figures.sh` from the saved captures. Wireshark screenshots of the same captures can replace them if the course requires the graphical tool.
- #todo[Each member writes their individual conclusion and CRediT table (below).]
- *Limitation:* signatures were generated on 2026-11-22 and are valid for 30 days (default of `dnssec-signzone`); there is no automatic re-signing, so the lab stops validating after that.

= Declaration of AI Use

#todo[Draft written from what happened in the session; the team must review and confirm it before delivery.]

The team used Claude Code (Anthropic) @claude during this activity [models Sonnet 5.5 and Opus 5.5, November 2026]. This is how it was used:

- *Planning.* It read the report of Activity 2 and proposed the tree, the addressing and the order of the steps, including the choice of algorithm and NSEC3 parameters, which the team approved.
- *Laboratory files.* It wrote the BIND configuration files, the zone files and the shell scripts in `lab/` (signing, installation, start-up, tests, tampering test, figures).
- *Running and diagnosing.* It ran the signing and analysis commands on the team's machine and read the outputs. The commands that need `sudo` (installing packages, assigning addresses, starting `named`) were run by a team member. While doing so it found and fixed a bug in its own signing script (duplicate root keys) and repeated the captures afterwards.
- *Report.* It drafted this document and the tables from the saved outputs. We checked the numbers against `lab/evidence/`.

The traffic captures and `dig`/`delv` outputs come from our own runs. The explanation of the extra root `NS` queries is marked as unconfirmed.

= Individual conclusions and CRediTs

== Angel Eduardo Luna

#todo[Individual conclusion (own words) and CRediT roles with the concrete contribution behind each one.]

== Jannette Cristina Flores Rodríguez

#todo[Individual conclusion (own words) and CRediT roles with the concrete contribution behind each one.]

== Montserrat Rodríguez Ramírez

#todo[Individual conclusion (own words) and CRediT roles with the concrete contribution behind each one.]

== Carolina Sarahí Sánchez Meneses

#todo[Individual conclusion (own words) and CRediT roles with the concrete contribution behind each one.]

== Elías Alejandro Corral Rodríguez

#todo[Individual conclusion (own words) and CRediT roles with the concrete contribution behind each one.]

#bibliography(
  bytes(
    "
rfc4033:
  type: web
  title: 'RFC 4033, DNS Security Introduction and Requirements'
  url: https://datatracker.ietf.org/doc/rfc4033/
rfc4035:
  type: web
  title: 'RFC 4035, Protocol Modifications for the DNS Security Extensions'
  url: https://datatracker.ietf.org/doc/rfc4035/
rfc5155:
  type: web
  title: 'RFC 5155, DNS Security (DNSSEC) Hashed Authenticated Denial of Existence'
  url: https://datatracker.ietf.org/doc/rfc5155/
rfc6605:
  type: web
  title: 'RFC 6605, ECDSA for DNSSEC'
  url: https://datatracker.ietf.org/doc/rfc6605/
rfc8624:
  type: web
  title: 'RFC 8624, Algorithm Implementation Requirements and Usage Guidance for DNSSEC'
  url: https://datatracker.ietf.org/doc/rfc8624/
rfc9276:
  type: web
  title: 'RFC 9276, Guidance for NSEC3 Parameter Settings'
  url: https://datatracker.ietf.org/doc/rfc9276/
claude:
  type: web
  title: Claude (large language model)
  author: Anthropic
  url: https://claude.ai
  date: 2026
bindarm:
  type: web
  title: BIND 9 Administrator Reference Manual
  url: https://bind9.readthedocs.io/
",
  ),
  title: "References",
  style: "ieee",
)
