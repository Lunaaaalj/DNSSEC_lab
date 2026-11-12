# 04. Highlighting inside screenshots (feedback 3)

Feedback: *"if possible you can highlight within screenshot for better readability."*

Goal: for each figure, draw attention to exactly the values the text quotes, so the reader can match prose, table and image at a glance.

## Method (pick one)

**A. Annotate the PNG (recommended: works in any viewer, survives export).**
macOS Preview → Markup → rectangle (red or orange, 3 px, no fill) and optionally a numbered callout. Save as a *new* file (`figures/annotated/…`) and keep the originals untouched. Export at the original resolution.

**B. Overlay in Typst (keeps originals; positions are fiddly).**
```typst
#box(image("../figures/soa dig.png", width: 100%))
// then place(top + left, dx: .., dy: .., rect(..)) inside a #block with relative positioning
```
Good if highlights must be re-adjusted, but coordinates need trial and error. Prefer A unless the team wants to tweak highlights often.

**Conventions (use the same in all figures)**
- One colour for highlights (red `#d32f2f`), 2–3 px outline, no fill, so text stays readable.
- Numbered markers ①②③ only when a figure has more than three highlights; explain them in the caption ("① flags, ② TTL, …").
- Highlight the **value**, not the whole line.
- Make sure the image is still legible at the printed width (page text width is about 16.5 cm); crop empty margins first.
- Add `Highlighted in red: …` to every caption so the highlight has a stated meaning.

## Per-figure highlight list

Values come from the screenshots in `docs/manuscript/figures/`. The Wireshark detail panes show the same numbers as `dig`, so keep both images but highlight different aspects.

| Fig. | Image | Highlight | Why (text it supports) |
|---|---|---|---|
| 1 | `real dig typst.png` | The Wireshark filter box (`dns.qry.name == "typst.app"`); the **last 8 rows** (frames 22532–24933) as one group; resolver IP `10.23.56.43` and client `10.23.76.254` in one row; the Time cells of frames 22556 and 23600 (183.404571 and 192.695664) | filter used; "last eight packets" statement; topology in Tab. 1; the 9 s TTL-countdown argument |
| 2 | `5.2.png` | `Authoritative: Server is not an authority` (AA=0); `Recursion desired` and `Recursion available` (RD, RA); `Questions/Answer RRs/Authority RRs/Additional RRs` counts; the three `Time to live: 4076`; the two `Time to live: 291`; `type OPT` block | flags discussion; Tab. 6 and Tab. 9 counts; TTL values |
| 3 | `soa dig.png` | the `flags: qr rd ra; … ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 3` line; the SOA answer line (86400 and the seven fields); `Query time: 198 msec`; `SERVER: 10.23.56.43#53`; `WHEN … 18:22:08` | Tab. 7; query-time claim; resolver identity; countdown timestamp |
| 4 | `soa wireshark.png` | `Serial Number`, `Refresh`, `Retry`, `Expire`, `Minimum TTL` rows together; `Time to live: 86400`; `Time to live: 300` for A/AAAA; `DO bit: Cannot handle DNSSEC security RRs`; `[Time: 198.021000 milliseconds]` | Tab. 7; Tab. 8; DO-bit remark; timing |
| 5 | `ns dig.png` | three NS lines with TTL 4076; flags line; `Query time` | Tab. 8 NS row; redundancy argument; fast (cached) answer |
| 6 | `ns wireshark.png` | frame row / response summary and the `[Time: …]` line (≈21.5 ms) | timing comparison with the SOA query |
| 7 | `a dig.png` | `150.171.109.104`, TTL `300`, `flags`, `Query time` | Tab. 8 A row; ≈20 ms claim |
| 8 | `a wireshark.png` | `Address: 150.171.109.104`, `Time to live: 300`; OPT → `DO bit` (0) | A-record and DO-bit statements |
| 9 | `aaaa dig.png` | `2603:1061:14:62::1`, TTL `300`, flags | Tab. 8 AAAA row |
| 10 | `aaaa wireshark.png` | `AAAA Address`, `Time to live: 300`, `Type: AAAA (28)` | AAAA statements; 128-bit address |

Before annotating, open each of Figs. 5–10 once and confirm the exact lines (this plan was written after looking at Figs. 1–4; I only inspected those four screenshots in detail).

## Extra improvements that help readability

- **Crop** Fig. 1 to the filter bar + table (already tight) and Fig. 4 to the detail pane (the unrelated toolbar slice at the top is noise).
- **Figure 3 / Figure 4 pairing:** consider placing each Terminal/Wireshark pair side by side in one figure with two sub-figures (`a`, `b`) to save space. This changes numbering (10 figures become 6 plus subfigures), which would invalidate the numbering in `02`. Only do it if the report is too long; otherwise keep the one-image-per-figure scheme that matches the labels.
- **Caption wording:** `[Figure caption sentence naming the record type, the tool, and what is highlighted.]` Example for Fig. 2:
  *"DNS response to the `typst.app` NS query (frame 23600) in Wireshark. Highlighted: header flags (AA = 0, RD = 1, RA = 1), section counts, TTL values and the OPT pseudo-record."*

## Privacy check while editing screenshots

The terminal prompts of the four `dig` screenshots (Figs. 3, 5, 7, 9) were redacted to a neutral `user@host ~ %` so no local username or hostname is published. Re-apply the same redaction to any new terminal screenshot. Internal network addresses (client and resolver) are part of the analysis and are kept.
