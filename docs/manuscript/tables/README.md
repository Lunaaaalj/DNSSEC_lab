# Shared tables

LaTeX table fragments used by every manuscript version (`v1`, `v2`, …). Images live in `../figures/`.

Convention:

- One table per file, named `tab-<topic>.tex`, wrapped in `\begin{table}…\end{table}`.
- Caption **above** the tabular (the shared preamble enforces `position=top`), `\label{tab:<topic>}`.
- Tables built from captures end with a note `Source: \cref{fig:…}` (review feedback #4).
- Include from a section file with `\input{../tables/tab-<topic>}`.
- Cite the table in the text with `\cref{tab:<topic>}` before it appears.

`tab-example.tex` is a placeholder demonstrating the pattern; delete it when real tables exist.
