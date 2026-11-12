# 03. Citations (feedback 2)

Feedback: *"include references at every place where you mention information either within the paragraph or after."*

Policy for v2:

1. Every sentence that states a **protocol fact, a configuration recommendation or a security claim** ends with a citation.
2. Every sentence that states a **measured value** points to a figure (`@fig-…`) rather than a bibliography entry. Observed values need a figure, and the interpretation of that value needs a citation.
3. Citations may also go **after** a paragraph when one source supports the whole paragraph (the reviewer allows "within the paragraph or after").
4. Results and Conclusions repeat the citation of the claim they restate.

## Claim → source map

Keys marked **(exists)** are already in `bibliography.bib`; **(new)** are proposed in the next section.

### Introduction / BIND / Configuration

| Claim | Where in v1 | Cite |
|---|---|---|
| DNS maps names to addresses; `hosts.txt` did not scale | Intro ¶1 | `rfc1034` (exists) |
| Resolver walks root → TLD → authoritative; TTL caching | Intro ¶2, 4.1 | `rfc1034`, `rfc1035` (exist); optionally `rfc9499` (terminology) |
| BIND history (Berkeley, 1980s, ISC, `named`) | 2.1 | `isc_bind9_arm` (exists); optionally `isc_bind_history` (new) |
| Authoritative answers carry `aa`; recursive carry `ra` | 2.2, Tab. 5 | `rfc1035` §4.1.1 (exists) |
| Zone declaration, `type primary/master`, zone file | 3.2 | `isc_bind9_arm` |
| `allow-transfer` restricts zone copies | 3.2 | `isc_bind9_arm`; background on zone transfers: `rfc5936` (new) |
| Authoritative-only servers should disable recursion (open resolver abuse) | 3.2 | `rfc5358` (new) |
| `allow-recursion` limits clients; open resolvers enable amplification (DDoS) | 3.3 | `rfc5358`, `cisa_ta14_017a` (new) |
| Cache poisoning risk for open/exposed resolvers | 3.3 | `rfc5452` (new) |
| SOA fields' meaning (refresh, retry, expire) | Tab. 4, Tab. 7 | `rfc1035` §3.3.13 |
| Serial convention `YYYYMMDDnn` | Tab. 7 | `rfc1912` (new) §2.2 |
| Negative TTL = SOA minimum | Tab. 4, 5.7 | `rfc2308` (exists) |
| `named-checkconf` / `named-checkzone` | 3.5 | `isc_bind9_arm` |
| Built-in root hints; `hint` zone | 4 | `isc_bind9_arm`, `isc_bindusers_2009` (exist) |
| Where to obtain the current hints file | 4.1 | `iana_root_files` (exists) |
| Root servers' role / requirements | 4.1 | `rfc7720` (new) |
| Private/isolated network needs its own hints | 4.1, Results | `isc_bind9_arm` (state the hint zone is where this is configured) |

### Traffic analysis (Section 5): interpret with RFCs, support with figures

| Claim | Figure (observed) | Cite (interpretation) |
|---|---|---|
| Four message sections | @fig-ns-response-sections | `rfc1035` §4.1 |
| Flags `0x8180`; QR, RD, RA set, AA clear → came from a recursive resolver | @fig-ns-response-sections, @fig-soa-dig | `rfc1035` §4.1.1 |
| Authority empty when the answer is complete | @fig-ns-response-sections | `rfc1034` §4.3 |
| Additional section carries helper records (glue-like) | @fig-ns-response-sections | `rfc1035` §4.1 / `rfc1034` §3.7.1 |
| OPT pseudo-record, UDP size 4000, EDNS version 0 | @fig-ns-response-sections | `rfc6891` (new) |
| DO bit = 0 → no DNSSEC data requested | @fig-soa-wireshark, @fig-a-wireshark | `rfc3225` (new), `rfc4035` (new) |
| NS records & delegation, redundancy of several servers | @fig-ns-dig | `rfc1034` §4.2; `rfc2182` (new): selection and operation of secondary servers (explicitly recommends diverse locations) |
| A = 32-bit IPv4; AAAA = 128-bit IPv6 | @fig-a-dig, @fig-aaaa-dig | `rfc1035` (A); `rfc3596` (new) (AAAA) |
| Dual stack | @fig-a-dig, @fig-aaaa-dig | `rfc4213` (new) |
| TTL = seconds a record may be cached | Tab. 8 | `rfc1035` §3.2.1; `rfc2181` §8 (new) |
| Cache TTL counts down (300 → 291 over ≈9 s) | @fig-capture-overview (timestamps), @fig-soa-dig, @fig-ns-response-sections | `rfc1035`, `rfc2181` §8 |
| Negative cache = min(SOA TTL, SOA minimum) | @tab-soa-typst | `rfc2308` §5 (exists) |
| A zone change can take up to the old TTL to propagate | Results | `rfc1034` §4.3.5, `rfc1035` |
| `dig` usage / flags | Methodology | `isc_bind9_arm` (dig is part of BIND tools); optionally `dig_man` (new) |
| Wireshark DNS dissection / filter syntax | Methodology | `wireshark_dns_ref` (new) |

### Results & Conclusions

Every sentence there is a restatement; carry over the citation of the original claim. The conclusion draft in `05` already includes the keys.

## New `bibliography.bib` entries

First, **fix the stray `*` on the last line** of the file (after the `anthropic2026sonnet55` entry).

RFC metadata below follows the same format as your existing entries (DOI pattern `10.17487/RFCnnnn`). Before pasting, check each title/author/year once at https://www.rfc-editor.org/rfc/rfcNNNN. I wrote these from memory and have not re-fetched them. Use `urldate` = the day you check.

```bibtex
@techreport{rfc1912,
    author = {Barr, D.},
    title = {Common {DNS} Operational and Configuration Errors},
    institution = {Internet Engineering Task Force},
    type = {Request for Comments},
    number = {1912},
    year = {1996},
    month = feb,
    doi = {10.17487/RFC1912},
    url = {https://www.rfc-editor.org/rfc/rfc1912},
}

@techreport{rfc2181,
    author = {Elz, R. and Bush, R.},
    title = {Clarifications to the {DNS} Specification},
    institution = {Internet Engineering Task Force},
    type = {Request for Comments},
    number = {2181},
    year = {1997},
    month = jul,
    doi = {10.17487/RFC2181},
    url = {https://www.rfc-editor.org/rfc/rfc2181},
}

@techreport{rfc2182,
    author = {Elz, R. and Bush, R. and Bradner, S. and Patton, M.},
    title = {Selection and Operation of Secondary {DNS} Servers},
    institution = {Internet Engineering Task Force},
    type = {Request for Comments},
    number = {2182},
    year = {1997},
    month = jul,
    doi = {10.17487/RFC2182},
    url = {https://www.rfc-editor.org/rfc/rfc2182},
}

@techreport{rfc3225,
    author = {Conrad, D.},
    title = {Indicating Resolver Support of {DNSSEC}},
    institution = {Internet Engineering Task Force},
    type = {Request for Comments},
    number = {3225},
    year = {2001},
    month = dec,
    doi = {10.17487/RFC3225},
    url = {https://www.rfc-editor.org/rfc/rfc3225},
}

@techreport{rfc3596,
    author = {Thomson, S. and Huitema, C. and Ksinant, V. and Souissi, M.},
    title = {{DNS} Extensions to Support {IP} Version 6},
    institution = {Internet Engineering Task Force},
    type = {Request for Comments},
    number = {3596},
    year = {2003},
    month = oct,
    doi = {10.17487/RFC3596},
    url = {https://www.rfc-editor.org/rfc/rfc3596},
}

@techreport{rfc4035,
    author = {Arends, R. and Austein, R. and Larson, M. and Massey, D. and Rose, S.},
    title = {Protocol Modifications for the {DNS} Security Extensions},
    institution = {Internet Engineering Task Force},
    type = {Request for Comments},
    number = {4035},
    year = {2005},
    month = mar,
    doi = {10.17487/RFC4035},
    url = {https://www.rfc-editor.org/rfc/rfc4035},
}

@techreport{rfc4213,
    author = {Nordmark, E. and Gilligan, R.},
    title = {Basic Transition Mechanisms for {IPv6} Hosts and Routers},
    institution = {Internet Engineering Task Force},
    type = {Request for Comments},
    number = {4213},
    year = {2005},
    month = oct,
    doi = {10.17487/RFC4213},
    url = {https://www.rfc-editor.org/rfc/rfc4213},
}

@techreport{rfc5358,
    author = {Damas, J. and Neves, F.},
    title = {Preventing Use of Recursive Nameservers in Reflector Attacks},
    institution = {Internet Engineering Task Force},
    type = {Request for Comments},
    number = {5358},
    year = {2008},
    month = oct,
    doi = {10.17487/RFC5358},
    url = {https://www.rfc-editor.org/rfc/rfc5358},
}

@techreport{rfc5452,
    author = {Hubert, A. and van Mook, R.},
    title = {Measures for Making {DNS} More Resilient against Forged Answers},
    institution = {Internet Engineering Task Force},
    type = {Request for Comments},
    number = {5452},
    year = {2009},
    month = jan,
    doi = {10.17487/RFC5452},
    url = {https://www.rfc-editor.org/rfc/rfc5452},
}

@techreport{rfc5936,
    author = {Lewis, E. and Hoenes, A.},
    title = {{DNS} Zone Transfer Protocol ({AXFR})},
    institution = {Internet Engineering Task Force},
    type = {Request for Comments},
    number = {5936},
    year = {2010},
    month = jun,
    doi = {10.17487/RFC5936},
    url = {https://www.rfc-editor.org/rfc/rfc5936},
}

@techreport{rfc6891,
    author = {Damas, J. and Graff, M. and Vixie, P.},
    title = {Extension Mechanisms for {DNS} ({EDNS(0)})},
    institution = {Internet Engineering Task Force},
    type = {Request for Comments},
    number = {6891},
    year = {2013},
    month = apr,
    doi = {10.17487/RFC6891},
    url = {https://www.rfc-editor.org/rfc/rfc6891},
}

@techreport{rfc7720,
    author = {Blanchet, M. and Aoun, L.-J.},
    title = {{DNS} Root Name Service Protocol and Deployment Requirements},
    institution = {Internet Engineering Task Force},
    type = {Request for Comments},
    number = {7720},
    year = {2015},
    month = dec,
    doi = {10.17487/RFC7720},
    url = {https://www.rfc-editor.org/rfc/rfc7720},
}

@techreport{rfc9499,
    author = {Hoffman, P. and Sullivan, A. and Fujiwara, K.},
    title = {{DNS} Terminology},
    institution = {Internet Engineering Task Force},
    type = {Request for Comments},
    number = {9499},
    year = {2024},
    month = mar,
    doi = {10.17487/RFC9499},
    url = {https://www.rfc-editor.org/rfc/rfc9499},
}
```

Non-RFC sources to look up and add (I have not fetched these; confirm the URL and title before citing):

| Key | What | Used for |
|---|---|---|
| `cisa_ta14_017a` | US-CERT/CISA alert TA14-017A, *UDP-Based Amplification Attacks* | amplification claim in 3.3 and Conclusions |
| `wireshark_dns_ref` | Wireshark display-filter reference for DNS (`dns.qry.name`, `dns.flags.*`) | Methodology |
| `dig_man` | `dig(1)` manual page or the BIND ARM tools section | explaining `dig` output fields |
| `isc_bind_history` | ISC page on BIND history | only if the BIND-origin sentence is kept |

Fastest verification route: ask me to fetch each RFC's metadata and fix the entries in one pass. That avoids typos in author lists.

## Citation style notes for Typst

- Existing keys use `@key`; for a specific section use a supplement: `@rfc1035[§4.1.1]` (renders with APA as "(Mockapetris, 1987, §4.1.1)").
- Two sources for one claim: `@rfc5358 @cisa_ta14_017a`.
- Table 2–5 cells: put the citation in the **caption** if the whole table comes from one source (cleaner than 5 inline cites).
- Check that every entry in the `.bib` is actually cited, because Typst prints only cited entries. A key that is cited but missing causes a compile error, which is a useful safety net.
