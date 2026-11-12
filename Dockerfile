# LaTeX build image: used by `make docker-run` and by the devcontainer (Codespaces).
# Debian packages instead of the full texlive/texlive image (~4 GB) to keep cold starts fast.
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# biblatex-apa comes from texlive-bibtex-extra; arxiv.sty is vendored in docs/common/.
RUN apt-get update && apt-get install -y --no-install-recommends \
        texlive-latex-recommended \
        texlive-latex-extra \
        texlive-fonts-recommended \
        texlive-bibtex-extra \
        biber \
        latexmk \
        make \
        git \
        ca-certificates \
        poppler-utils \
    && rm -rf /var/lib/apt/lists/*

# Fail the image build early if a file the documents need is missing.
RUN for f in apa.bbx cleveref.sty csquotes.sty microtype.sty booktabs.sty listings.sty \
             enumitem.sty fancyhdr.sty ptmr8t.fd; do \
        kpsewhich "$f" >/dev/null || { echo "missing TeX file: $f" >&2; exit 1; }; \
    done

# Non-root user (UID 1000 matches the default Codespaces/devcontainer user).
RUN useradd --create-home --shell /bin/bash --uid 1000 vscode
USER vscode

WORKDIR /work
CMD ["make", "all"]
