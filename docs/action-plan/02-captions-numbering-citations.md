# 02. Captions, numbering and in-text references (feedback 1, 4, 5, 7, 8)

Verified against the installed Typst (0.15.1).

## 1. Table captions on top

Add once, in the global setup (after `#set figure(placement: none)`):

```typst
#show figure.where(kind: table): set figure.caption(position: top)
```

Figure captions stay below (the standard convention, and the reviewer only asked for tables). Optionally keep a small gap:

```typst
#show figure.where(kind: table): set block(breakable: false)   // avoid splitting table from caption
```

Long tables that split across pages (Tab. 3, 6, 8) may need `breakable` left on; check the PDF.

## 2. Label every float

Naming scheme (readable, stable if the order changes):

| Auto no. | Label | Auto no. | Label |
|---|---|---|---|
| Fig. 1 | `<fig-capture-overview>` | Tab. 1 | `<tab-environment>` |
| Fig. 2 | `<fig-ns-response-sections>` | Tab. 2 | `<tab-bind-functions>` |
| Fig. 3 | `<fig-soa-dig>` | Tab. 3 | `<tab-config-files>` |
| Fig. 4 | `<fig-soa-wireshark>` | Tab. 4 | `<tab-soa-fields-example>` |
| Fig. 5 | `<fig-ns-dig>` | Tab. 5 | `<tab-auth-vs-rec>` |
| Fig. 6 | `<fig-ns-wireshark>` | Tab. 6 | `<tab-response-sections>` |
| Fig. 7 | `<fig-a-dig>` | Tab. 7 | `<tab-soa-typst>` |
| Fig. 8 | `<fig-a-wireshark>` | Tab. 8 | `<tab-ttl-summary>` |
| Fig. 9 | `<fig-aaaa-dig>` | Tab. 9 | `<tab-results-sections>` |
| Fig. 10 | `<fig-aaaa-wireshark>` | | |

Typst syntax: put the label right after the closing parenthesis of the figure:

```typst
#figure(
  image("../figures/soa dig.png", width: 100%),
  caption: [SOA query and response for `typst.app` in Terminal.],
) <fig-soa-dig>
```

Also label the sections that prose refers to by number (replace the hard-coded "Section 3", "Section 5"):

`<sec-config>`, `<sec-root-hints>`, `<sec-analysis>`, `<sec-ttl>`, then write `@sec-analysis` (needs `#set heading(numbering: "1.1.")`, already present, and `supplement: [Section]`, which is the default for headings).

## 3. Cite every float in the text (feedback 8)

Rule of thumb: **the paragraph that discusses a float contains its `@ref` before the float appears.** Never rely on the reader noticing it.

Reference plan (where to insert the first mention):

| Float | Mention it in | Suggested wording |
|---|---|---|
| Tab. 1 `@tab-environment` | Intro, "Environment used…" | "The environment is summarized in @tab-environment." |
| Tab. 2 `@tab-bind-functions` | 2.2 | "…the main functions are listed in @tab-bind-functions." |
| Tab. 3 `@tab-config-files` | 3.1 (replaces "The table shows…") | "@tab-config-files shows which file controls each part." |
| Tab. 4 `@tab-soa-fields-example` | right under the zone-file listing, "The fields of the SOA record are:" | "The fields of the SOA record in the example zone are described in @tab-soa-fields-example." |
| Tab. 5 `@tab-auth-vs-rec` | 3.4 lead-in | "@tab-auth-vs-rec contrasts…" |
| Fig. 1 `@fig-capture-overview` | 5.1 methodology, after the `dig` commands | "…captured packets are shown in @fig-capture-overview." |
| Tab. 6, Fig. 2 | 5.2 | "@tab-response-sections describes each section; @fig-ns-response-sections shows them in the NS response." |
| Tab. 7, Figs. 3, 4 | 5.3 | "@tab-soa-typst lists the fields (see @fig-soa-dig and @fig-soa-wireshark)." |
| Figs. 5, 6 | 5.4 | "(@fig-ns-dig, @fig-ns-wireshark)" |
| Figs. 7, 8 | 5.5 | "(@fig-a-dig, @fig-a-wireshark)" |
| Figs. 9, 10 | 5.6 | "(@fig-aaaa-dig, @fig-aaaa-wireshark)" |
| Tab. 8 | 5.7 | "@tab-ttl-summary" |
| Tab. 9 | 6.3 | "@tab-results-sections" |

Also use figure references **inside the discussion of numbers** (e.g. "TTL of 4076 s (@fig-ns-response-sections)"), not just at the start of the subsection. The reviewer wants to be able to find the value.

## 4. Tables built from captures must name their source figure (feedback 4)

Applies to Tab. 1, 6, 7, 8, 9. Two options (pick one and apply it consistently):

**Option A: in the caption (recommended: stays attached to the table):**

```typst
caption: [Fields of the SOA record of `typst.app`. Values taken from @fig-soa-dig and @fig-soa-wireshark.],
```

**Option B: a "Source" column or line.** Heavier; only worth it for Tab. 8 because every row comes from a different figure.

Source map for the tables:

| Table | Source figures |
|---|---|
| Tab. 1 Environment | IPs and interface: @fig-capture-overview; `dig` version: @fig-soa-dig; Wireshark version: needs a screenshot or a citation (see below) |
| Tab. 6 Response sections | @fig-ns-response-sections (the Observed column) |
| Tab. 7 SOA of `typst.app` | @fig-soa-dig, @fig-soa-wireshark |
| Tab. 8 TTL summary | row by row: SOA → @fig-soa-dig; NS → @fig-ns-dig; A → @fig-a-dig; AAAA → @fig-aaaa-dig; A/AAAA of `ns.inwx.de.` 300 s → @fig-soa-dig, 291 s → @fig-ns-response-sections |
| Tab. 9 Sections summary | @fig-ns-response-sections |

**Gap:** the Wireshark version (4.6.9) and macOS version (15.6.1) appear in Tab. 1 with no evidence. Either take one extra screenshot (Wireshark → About, `sw_vers`), or drop the build hash and say "as reported by Wireshark's About dialog". Decide with the team; it is a small thing but the reviewer asked for a figure behind every table value.

Tab. 2–5 are theory, so no source figure; they get **citations** in the caption or cells (see `03`).

## 5. Do not number "References" and "Declaration of AI Use" (feedback 7)

`= References` inherits the heading numbering. Replace both with:

```typst
#heading(level: 1, numbering: none)[References]
#bibliography("../../../bibliography.bib", style: "apa", title: none)

#heading(level: 1, numbering: none)[Declaration of AI Use]
```

They still appear in the table of contents, which is what you want. (`outline(depth: 3)` is unaffected.)

## 6. Bonus: code listings

The four code blocks (`named.conf.local`, `named.conf.options` ×2, zone file) are not floats. The feedback is about figures and tables, so leave them. If the team wants every artifact referenced, wrap them in `figure(kind: raw)` with captions "Listing n". That is optional scope; not recommended.
