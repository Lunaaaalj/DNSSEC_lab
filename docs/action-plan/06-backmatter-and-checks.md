# 06. Back matter and final checks (feedback 7, 8)

## Back matter (feedback 7)

Both sections must be **unnumbered** but **still in the table of contents**:

```typst
#heading(level: 1, numbering: none)[References]
#bibliography("../../../bibliography.bib", style: "apa", title: none)

#heading(level: 1, numbering: none)[Declaration of AI Use]
```

Path note: v1 sits in `docs/manuscript/v1/`. If v2 goes in `docs/manuscript/v2/`, the relative paths to `../figures/` and `../../../bibliography.bib` stay valid. If you place it elsewhere, recompute both.

The Declaration of AI Use should be **updated for v2**: if Claude is used again to help with this revision (plan, references, caption/label edits), say so, with dates. It currently says use ended on November 9, 2026. State what changed: "revision planning and reference suggestions," and that the team verified the added RFC entries against rfc-editor.org. Keep it unnumbered. It should also cite the model entry already in the bibliography (`anthropic2026sonnet55`), but note that the key is cited only in that section.

## Final verification checklist (run before submitting v2)

Build: `typst compile docs/manuscript/v2/main.typ` (must finish with no warnings about missing labels or keys).

| # | Check | How |
|---|---|---|
| 1 | All 9 table captions are **above** their tables | Skim the PDF; or run `pdftotext -layout` and look for "Table n:" before the rows |
| 2 | Every figure and table has a label | `grep -c "^) <fig-\|^) <tab-" main.typ`; expect 19 |
| 3 | Every label is referenced | for each label: `grep -c "@fig-name"`; 0 means a float nobody cites. Typst will not warn |
| 4 | No hard-coded "Table 7", "Figure 3", "Section 5" in prose | `grep -nE "(Table\|Figure\|Fig\.\|Section) [0-9]" main.typ`; expect none |
| 5 | Each capture-derived table names its source figure(s) | Tab. 1, 6, 7, 8, 9 (see `02`) |
| 6 | Figure references appear next to the numbers they support, not just in the intro | Read §5 and §6 once with that purpose |
| 7 | Every paragraph with protocol facts or security claims has a citation | Read each section against the claim map in `03` |
| 8 | Results and Conclusions are cited | They were uncited in v1 |
| 9 | References and Declaration of AI Use unnumbered, but in Contents | Check page with the outline |
| 10 | Conclusion is prose (no `+` list items under `= Conclusions`) | Skim |
| 11 | All 10 images are highlighted and each caption says what the highlight is | Visual check |
| 12 | Stray `*` removed from `bibliography.bib`; new entries verified against rfc-editor.org | `typst compile` fails on bad entries |
| 13 | Heading typo fixed: `Environment used for the traffic analysis,` | grep |
| 14 | No terminal screenshot shows a real username or hostname | Visual check of every `dig` figure |
| 15 | Table numbers did not shift: Tab. 1–9 in the same order as in `01-audit.md` | otherwise the plan's mapping is stale |

## Suggested v2 workflow in git

- Copy `docs/manuscript/v1/` to `docs/manuscript/v2/` first; don't edit v1 (it is the reviewed version and a useful diff base).
- One commit per feedback item (caption position, numbering/labels, highlights, citations, conclusion, back matter) so each can be reviewed against the original comment.
- Optionally keep a short `CHANGES.md` mapping each reviewer comment to the commit. Useful if the instructor asks how feedback was addressed.
