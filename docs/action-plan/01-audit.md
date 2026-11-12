# 01. Audit of v1

Numbers below are the ones Typst assigns automatically, in document order. They will not change as long as the order of floats does not change.

## Figures (10)

| Fig. | File | Section | Caption (v1) | Cited in text? | Highlighted? |
|---|---|---|---|---|---|
| 1 | `real dig typst.png` | 5 Methodology | DNS packets for `typst.app`… | No | No |
| 2 | `5.2.png` | 5.2 Sections | DNS response packet with its four sections | No | No |
| 3 | `soa dig.png` | 5.3 SOA | SOA query/response in Terminal | No | No |
| 4 | `soa wireshark.png` | 5.3 SOA | SOA query/response in Wireshark | No | No |
| 5 | `ns dig.png` | 5.4 NS | NS in Terminal | No | No |
| 6 | `ns wireshark.png` | 5.4 NS | NS in Wireshark | No | No |
| 7 | `a dig.png` | 5.5 A | A in Terminal | No | No |
| 8 | `a wireshark.png` | 5.5 A | A in Wireshark | No | No |
| 9 | `aaaa dig.png` | 5.6 AAAA | AAAA in Terminal | No | No |
| 10 | `aaaa wireshark.png` | 5.6 AAAA | AAAA in Wireshark | No | No |

Observation: Fig. 2 is the NS response (transaction `0x7e8f`, frame 23600), but its caption does not say so. Name the record type in the caption.

## Tables (9)

| Tab. | Section | Content | Caption position | Built from captures? | Source figure named? | Cited in text? |
|---|---|---|---|---|---|---|
| 1 | 1.2 Environment | Versions, IPs | below | Yes (IPs, `dig` version) | No | No |
| 2 | 2.2 Main functions | BIND functions | below | No (theory) | n/a | No |
| 3 | 3.1 Config files | File locations | below | No (theory) | n/a | No ("The table shows…") |
| 4 | 3.2 Auth. server | SOA fields of the *example* zone | below | No (example) | n/a | No |
| 5 | 3.4 Comparison | Auth vs recursive | below | No (theory) | n/a | No |
| 6 | 5.2 Response sections | Question/Answer/Authority/Additional | below | Yes | No | No |
| 7 | 5.3 SOA | SOA fields of `typst.app` | below | Yes | No | No |
| 8 | 5.7 TTL summary | TTL per record | below | Yes | No | No |
| 9 | 6.3 Results | Sections summary | below | Yes | No | No |

Tables that need a source figure (feedback #4): **1, 6, 7, 8, 9**.
Tables 2–5 are theory; they need a *citation* (feedback #2) rather than a figure.

## Where v1 states capture-derived facts with no pointer

| Claim in text | Value | Evidence lives in |
|---|---|---|
| Flags `0x8180`, QR/RD/RA set, AA clear | all responses | Fig. 2 (flags tree), Figs. 3, 5, 7, 9 (`flags: qr rd ra`) |
| 3 NS records, TTL 4076 s | NS query | Figs. 5, 6, 2 |
| Additional: A/AAAA of `ns.inwx.de.`, TTL 291 s | NS response | Fig. 2 |
| SOA fields, TTL 86400, serial 2026101700 | SOA query | Figs. 3, 4 |
| Query time 198 ms vs ≈20 ms | SOA vs others | Fig. 3 (`Query time`), Figs. 6, 8, 10 (`[Time: …]`) |
| `typst.app` → 150.171.109.104, TTL 300 | A query | Figs. 7, 8 |
| `typst.app` → 2603:1061:14:62::1, TTL 300 | AAAA query | Figs. 9, 10 |
| DO bit = 0 | A query (and others) | Fig. 8 (OPT → Z flags), Fig. 4 |
| TTL 300 → 291 over 9 s (frames 22556, 23600) | countdown | Fig. 1 (timestamps 183.404571 and 192.695664), Figs. 4, 2 |
| Client 10.23.76.254, resolver 10.23.56.43 | topology | Fig. 1 |

Quick check of the countdown claim: 192.695664 − 183.404571 = 9.29 s, consistent with the text's "about 9.3 s".

## Citation gaps (feedback #2), summarized

- **Introduction**: the first paragraph is cited. The third (goal paragraph) needs no source.
- **2 Config / 3 BIND**: the `allow-recursion` security claim (amplification, cache poisoning) is uncited. The `allow-transfer` statement is uncited. The root-hint explanation in 4 is half-cited.
- **5 Analysis**: most prose asserts RFC-defined behaviour (flags, EDNS, Additional section, dual stack, cache countdown) but cites only RFC 1035 or 2308 occasionally.
- **6 Results and Discussion**: **no citations at all**, although it restates theory.
- **7 Conclusions**: no citations. A conclusion can restate cited findings, but the facts it restates (RFC 2308 behaviour, amplification) should carry the same citation.
- **Tables 2–5**: only some cells carry citations.
