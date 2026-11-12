# 05. Conclusions in paragraphs (feedback 6)

v1 has seven numbered items. Replace them with **four paragraphs**, one per theme, each ending with its citation or figure reference. This keeps every finding of the list but links them into an argument. Draft below. It is a *proposal*; edit freely, and keep `@…` labels in sync with `02`.

Rules used:
- No lists and no new facts. Everything restated appears in the body (and carries its citation or figure).
- Conclusion mentions at least one figure/table so the reader can trace the claim.
- The last paragraph looks forward to the DNSSEC lab, as in v1.

## Draft (Typst)

```typst
= Conclusions

This activity showed that BIND can act as an authoritative server, a recursive resolver, or both, and that the role is determined by a small, clearly separated part of its configuration @isc_bind9_arm. The authoritative role is defined by the zone declarations in `named.conf.local` and the zone files, while the recursive role is defined by the `recursion` and `allow-recursion` options in `named.conf.options` (@tab-config-files, @tab-auth-vs-rec). Keeping the two roles separate is also a security practice: an authoritative-only server should set `recursion no`, and a recursive server should restrict its clients, so that neither becomes an open resolver that can be abused for amplification attacks or cache poisoning @rfc5358 @rfc5452.

The `root.hints` file is the starting point of every recursive resolution, because a resolver with an empty cache must learn where the root servers are before it can follow the referrals to the TLD and authoritative servers @rfc1034 @isc_bind9_arm. BIND includes a built-in copy of this list @isc_bindusers_2009, but declaring the file explicitly allows the list to be updated @iana_root_files or replaced, which is essential in an isolated network where the real root servers are unreachable.

The captures of `typst.app` made with `dig` and Wireshark confirmed the structure of a DNS response. All four sections were observed (@fig-ns-response-sections, @tab-response-sections), and the Additional section carried the address records of `ns.inwx.de.` and the EDNS OPT pseudo-record, which spare the client extra queries @rfc1035 @rfc6891. The header flags (QR, RD and RA set, AA clear) showed that every answer came from the network's recursive resolver and not from an authoritative server of the domain @rfc1035 (@fig-soa-dig, @fig-ns-wireshark). The TTL proved to be a property of each record set, with 86400 s for the SOA, 4076 s for the NS records and 300 s for the A and AAAA records (@tab-ttl-summary). The addresses of `ns.inwx.de.` dropped from 300 s to 291 s in the 9 seconds between two queries (@fig-capture-overview), which showed the cache countdown directly and explains why a zone change can take up to the old TTL to reach every resolver @rfc2181. This record TTL controls how long existing records are cached; the SOA minimum field (3600 s) controls something different, namely how long the non-existence of a name is remembered @rfc2308 (@tab-soa-typst).

Finally, the OPT record showed the DO bit set to 0, meaning that the client did not request DNSSEC data (@fig-a-wireshark) @rfc3225. The knowledge gained here (zone files, recursion, root hints, message structure and TTL behavior) is the foundation for the next lab, in which DNSSEC will be implemented @rfc4035.
```

## Notes

- Paragraph 3 is long. If it reads heavy, split after "…the EDNS OPT pseudo-record…" and start a new paragraph at "The TTL proved…". Four to five paragraphs is fine; the reviewer's request is simply *prose, not a list*.
- Check each `@fig-…` against the final highlighted images; for example, the 21.5 ms Wireshark timing the draft implicitly relies on is in Fig. 6 (not yet inspected) and the 20 ms claim of v1 should be confirmed against Figs. 6, 8 and 10.
- `rfc3225`, `rfc4035`, `rfc5358`, `rfc5452`, `rfc2181` and `rfc6891` are new entries (see `03`). If any is dropped, drop its citation here too.
- Do not repeat "Section 5" numbers in prose; use `@sec-analysis` if a section reference is needed.
