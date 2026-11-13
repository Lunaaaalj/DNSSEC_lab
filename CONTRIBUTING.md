# Contributing

This repository holds the team report on DNS with BIND (manuscript v1 in Typst, v2 in LaTeX) and the follow-up action plans. This guide covers how to set up, build, write and submit changes.

- [Repository map](#repository-map)
- [Set up your environment](#set-up-your-environment)
- [Build the documents](#build-the-documents)
- [Branches and pull requests](#branches-and-pull-requests)
- [Writing conventions (LaTeX)](#writing-conventions-latex)
- [Figures, tables and screenshots](#figures-tables-and-screenshots)
- [Citations and the bibliography](#citations-and-the-bibliography)
- [Personal action plans](#personal-action-plans)
- [Commit messages](#commit-messages)
- [What never to commit](#what-never-to-commit)
- [Licensing and AI use](#licensing-and-ai-use)

## Repository map

```
bibliography.bib            shared bibliography (one file for every document)
Makefile  Dockerfile  .devcontainer/    build entry points
docs/
  common/                   arxiv.sty (vendored) and preamble.tex, shared by all LaTeX documents
  manuscript/
    figures/  tables/       shared by every manuscript version
    v1/                     Typst baseline (the version that was reviewed; do not edit)
    v2/                     LaTeX manuscript: main.tex, latexmkrc, sections/
  action-plan/
    *.md                    team analysis of the reviewer feedback
    template/               LaTeX template every member copies
personal/                   YOUR plan(s); git-ignored, local only
```

Each LaTeX document is modular: `main.tex` only sets up the page and `\input`s one file per section from `sections/`.

## Set up your environment

Pick one. All three produce the same PDFs.

| Option | When to use | How |
|---|---|---|
| **Codespaces / devcontainer** | Nothing to install | Open the repo in a Codespace or "Reopen in Container" in VS Code. LaTeX Workshop builds on save into `build/`. |
| **Docker** | Same toolchain locally | `make docker-build` once, then `make docker-run` (or `make docker-run TARGET=personal`). |
| **Native TeX Live** | Fastest iteration | Install TeX Live (or MacTeX) with `latexmk`, `biber` and the packages `biblatex-apa`, `cleveref`, `csquotes`, `microtype`, `booktabs`, `listings`, `enumitem`. |

No `-shell-escape` is needed; do not add packages that require it (such as `minted`).

For the Typst v1 baseline only: `typst compile --root . docs/manuscript/v1/main.typ`.

## Build the documents

Run these from the repository root:

| Command | What it does |
|---|---|
| `make` | Show the help |
| `make all` | Build the shared documents (manuscript v2 and the action-plan template) |
| `make manuscript` / `make template` | Build one of them |
| `make personal` | Build every `personal/<name>/` that has a `main.tex` |
| `make watch DOC=docs/manuscript/v2` | Rebuild on every save |
| `make clean` | Remove auxiliary files, keep the PDFs |
| `make distclean` | Remove every `build/` directory |

Every document has its own `latexmkrc`; all artifacts, **including the PDF**, go to `<document>/build/`. You can also build one document directly: `cd docs/manuscript/v2 && latexmk`.

If a build fails, read the first `!` error in `build/main.log`; `-halt-on-error` stops at it. Warnings about undefined references on the first pass are normal and disappear on the rerun that latexmk does automatically.

## Branches and pull requests

`main` and `manuscript` are protected by a repository ruleset:

- no direct pushes, no force-pushes, no deletion;
- changes arrive by pull request, with **1 approving review**, new pushes dismiss stale approvals, and review threads must be resolved before merging.

Suggested flow:

1. `manuscript` is the integration branch for report writing; `main` receives stable, reviewed states.
2. Branch from `manuscript` for your work: `git switch manuscript && git pull && git switch -c <area>/<short-topic>`, for example `v2/results-section` or `build/ci`.
3. Keep a branch focused on one thing (one section, one fix, one tooling change) so review is quick.
4. Open a PR into `manuscript` (or into `main` for tooling and documentation that is not part of the manuscript). Describe what changed and what a reviewer should check, and link the feedback item it addresses when there is one.
5. Build before you request review: `make all` must pass, and the PDF should show no `??` or `[?]`.
6. Review someone else's PR by checking out the branch, building it, and reading the rendered PDF, not only the diff.
7. Do not rewrite history on a shared branch. If something sensitive was committed, tell the maintainer; do not force-push.

The maintainer can bypass the review requirement through a PR only (to merge their own PR when there is no second reviewer). That is an exception for a small team, not the norm.

## Writing conventions (LaTeX)

These encode the reviewer feedback on v1 and are the main review checklist.

- **Cite every float in the text.** Label each figure, table and section, and refer to them with `\cref{fig:...}`, `\cref{tab:...}`, `\cref{sec:...}`. Never type "Figure 3" or "Section 5" by hand: numbers change when content moves.
- **Cite the float before it appears,** and again next to the numbers it supports, not only once at the start of a subsection.
- **Table captions go above the table; figure captions go below.** The shared preamble already does this; don't override it.
- **Tables built from captures name their source figure** (`Source: \cref{fig:...}` under the table, or in the caption). Theory tables get a citation instead.
- **Cite every factual statement,** within the paragraph or right after it. Measured values point to a figure; their interpretation cites a source.
- **Conclusions are written in paragraphs,** not lists.
- **References and Declaration of AI Use are unnumbered** but still appear in the table of contents: use `\unnumberedsection{...}` or `\printbibliography[heading=bibintoc, ...]`, as `sections/08-` and `09-` do.
- **One section per file** in `sections/`, numbered (`05-traffic-analysis.tex`). Put `\section{...}\label{sec:...}` at the top of the file.
- Label naming: `fig:soa-dig`, `tab:ttl-summary`, `sec:analysis`. Lowercase, hyphenated, descriptive.
- Use the shared macros from `docs/common/preamble.tex`: `\code{...}` for inline code, `\todo{...}` for visible pending items (grep for `TO DO` before a release).
- Use `lstlisting` for code blocks (no `minted`).
- Files are UTF-8, so accented characters can be typed directly (`é`, `ñ`).

## Figures, tables and screenshots

- Images go in `docs/manuscript/figures/`, table fragments in `docs/manuscript/tables/` (see its README). They are shared by every manuscript version, so do not copy them into a version folder.
- Include a figure with the bare file name (`\includegraphics{soa dig.png}`); the search path is configured by each document's `latexmkrc`. Include a table fragment with `\input{../tables/tab-<topic>}`.
- **Highlight within screenshots** the exact values the text quotes (one colour, no fill), and say in the caption what is highlighted. Keep original captures untouched and save annotated versions under a clear name.
- **Redact before you commit.** Screenshots must not show real usernames, hostnames, emails, tokens, or unrelated traffic. In terminals, replace the prompt with `user@host ~ %`. Look at the whole image, including window titles and the Wireshark packet list. The repository is public; anything committed can be recovered from history even after a later fix.
- Prefer PNG, crop to the relevant area, and keep images legible at the printed width.

## Citations and the bibliography

- There is one `bibliography.bib` at the repository root, used with `biblatex` (APA style) and `biber`.
- Cite with `\parencite{key}` (parenthetical) or `\textcite{key}` (narrative). With an RFC section: `\parencite[§4.1.1]{rfc1035}`.
- Entry keys: `rfcNNNN` for RFCs; otherwise `<org-or-author>_<topic>_<year>`, lowercase.
- Prefer primary sources: RFCs from rfc-editor.org (with the DOI), vendor manuals, and official documentation.
- **Verify every entry against the source** (title, authors, year, URL) before you cite it, and add `urldate` for web pages. Do not copy entries from memory or from an AI tool without checking.
- Keep entries valid BibTeX: one entry per key, no stray characters after the closing brace. A bad entry breaks every document.
- Only cited entries are printed, so adding an entry never changes a document until it is cited.

## Personal action plans

Each member writes their own action plan in `personal/<name>/` (git-ignored; back it up yourself).

```bash
make new-plan NAME=angel AUTHOR="Angel Eduardo Luna" ID=A00842657
make personal
make watch DOC=personal/angel
```

- `NAME` is a folder name (`[A-Za-z0-9_-]+`); the command never overwrites an existing folder.
- The template is `docs/action-plan/template/`. Changes that should reach everybody belong there, via a PR.
- The shared notes in `docs/action-plan/*.md` are the team analysis of the feedback; the `% SOURCE:` comments in each section point to them.

## Commit messages

Use the existing style, `type(scope): summary` in the imperative, with a body that explains why:

```
docs(manuscript): add results section skeleton
build: pass TARGET to docker-run
fix(bib): remove duplicate key rfc2308
```

Types used so far: `docs`, `build`, `chore`. Use `fix` for corrections and `feat` for new tooling when they fit. Keep commits atomic: one logical change each, and do not mix tooling changes with writing.

## What never to commit

- `build/` directories, `.aux/.log/.bbl/.bcf` and other LaTeX artifacts (already ignored).
- Anything under `personal/` (ignored on purpose).
- Credentials, tokens, private keys, or `.env` files.
- Unredacted screenshots (see above) and files with unrelated personal data.
- Large binaries that are not part of the report.

If you commit one by mistake, do not try to fix it yourself with a force-push: tell the maintainer so history can be cleaned and caches purged.

## Licensing and AI use

- The repository is MIT-licensed (see `LICENSE`); by contributing you agree your contribution is published under it. The vendored `docs/common/arxiv.sty` keeps its own MIT license next to it.
- If you use an AI assistant for the report, record what it was used for, on which dates, and what you verified, in the **Declaration of AI Use** section. You are responsible for the content: check every claim, citation and number against the sources and your own captures.
