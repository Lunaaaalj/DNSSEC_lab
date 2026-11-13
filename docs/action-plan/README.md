# Action plan: manuscript v1 → v2

Source feedback: `docs/manuscript/docs/action-plan/feedback.txt` (8 comments).
Manuscript audited: `docs/manuscript/v1/main.typ` (10 figures, 9 tables, 0 labels, 0 cross-references).

## Files in this plan

| File | Covers | Feedback items |
|---|---|---|
| `01-audit.md` | Inventory of every figure and table, and what is wrong with each | all |
| `02-captions-numbering-citations.md` | Typst mechanics: captions on top, labels, `@` references, table→figure source notes | 1, 4, 5, 7, 8 |
| `03-references.md` | Where citations are missing, claim→source map, new `bibliography.bib` entries | 2 |
| `04-screenshot-highlights.md` | What to highlight in each of the 10 figures, and how | 3 |
| `05-conclusions.md` | Draft conclusion in paragraphs (the 7-item list rewritten) | 6 |
| `06-backmatter-and-checks.md` | Unnumbered References / AI Declaration, final verification checklist | 4 (numbering), 8 |

## Feedback → action traceability

| # | Feedback | Root cause in v1 | Fix | Effort |
|---|---|---|---|---|
| 1 | Table captions on top | Typst puts every caption below by default | One `show figure.where(kind: table)` rule | 1 line |
| 2 | Cite wherever information is mentioned | Results, Conclusions, TTL analysis, security claims and most capture-derived facts have no source | Claim→source map in `03` | Largest task |
| 3 | Number screenshots as Figures, mention figure numbers in text | Figures are auto-numbered but nothing in the text points to them (no labels, no `@ref`) | Label every figure, add `@fig-…` in text | Medium |
| 4 | Tables built from captures must name the source figure | Tables 1, 6–9 contain capture values but never point to a figure | Add `Source:` line / `@fig-…` in each caption or lead-in | Medium |
| 5 | Highlight inside screenshots | Screenshots are raw | Annotate 10 images (`04`) | Medium |
| 6 | Conclusion in paragraphs | Conclusions are a 7-item numbered list | Rewrite as 3–4 paragraphs (`05`) | Small |
| 7 | Do not number References and AI Declaration | Both are `=` headings, so they inherit `1.1.` numbering | `#heading(numbering: none)[…]` | 2 lines |
| 8 | Cite all figures and tables in text | Zero `@` references exist | Labels + `@` for all 19 items | Medium |

Items 3, 4 and 8 are the same job in practice: give every float a label, then reference it from the paragraph that discusses it.

## Personal action plans (LaTeX)

Each team member writes their **own** action plan. Plans live in `personal/<name>/`, which is git-ignored (local to you; back it up yourself).

```bash
make new-plan NAME=angel AUTHOR="Angel Eduardo Luna" ID=A00842657   # copy the template
make personal                                                       # build every personal plan
make watch DOC=personal/angel                                       # rebuild on save
```

- Template: `docs/action-plan/template/` (builds with `make template`; edit it to change what everyone starts from).
- `NAME` is a folder slug (`[A-Za-z0-9_-]+`); `new-plan` never overwrites an existing folder. `AUTHOR` and `ID` are optional and can be edited in `main.tex` later.
- Output: `personal/<name>/build/main.pdf`.
- No `../` paths: the plan's `latexmkrc` finds the repo root and exposes `docs/common` (template), `docs/manuscript/figures` (shared screenshots, use `\includegraphics{soa dig.png}`) and `bibliography.bib`.
- The shared notes `01`-`06-*.md` in this folder are the common analysis of the feedback; the `% SOURCE:` comments in each section point to them.

## Suggested working order

1. `02`: do the Typst plumbing first (caption position, unnumbered headings, labels). It is mechanical and every later edit depends on the labels.
2. `04`: annotate the screenshots. The highlighted image is what the text will point to.
3. `03`: add citations while rewriting each paragraph, adding the `@fig`/`@tab` references in the same pass.
4. `05`: rewrite the conclusion last, since it summarizes the final text.
5. `06`: run the checklist and compile.

## Things noticed while auditing (not in the feedback, but worth fixing in the same pass)

- Hard-coded section numbers in prose ("Section 3", "Section 5") will break as soon as headings move. Replace with `@sec-…` labels.
- The Environment heading has a stray trailing comma: `== Environment used for the traffic analysis,`.
- `bibliography.bib` ends with a stray `*` after the last entry (line 72). Remove it before adding entries or the parser may choke.
- An unused screenshot with unrelated browsing traffic was removed from the repository (including its history) before publishing.
- Figure 1 frame 1708 shows `typst.app A 150.171.109.100`, while the `dig` query (frame 24325) returns `…109.104`. Both are real, and the browser's earlier lookup got a different A record. Either explain this in one sentence (round-robin or multiple A records) or state that the first four packets are the browser's own lookups, which the text currently skips over.
- Placement: the plan files live in `docs/action-plan/` as requested, but `feedback.txt` currently sits in `docs/manuscript/docs/action-plan/` (untracked). Consider moving it next to these files.
