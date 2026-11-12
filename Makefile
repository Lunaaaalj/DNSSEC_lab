# Build entry point for every LaTeX document in this repository.
#
#   make              show this help
#   make all          build all documents
#   make manuscript   build docs/manuscript/v2
#   make action-plan  build docs/action-plan/document
#   make watch DOC=docs/manuscript/v2   rebuild on every save
#   make clean        remove auxiliary files (keeps the PDFs)
#   make distclean    remove the build/ directories
#   make docker-build / docker-run      same build inside the container
#
# Each document owns a latexmkrc; all artifacts (PDF included) go to <doc>/build/.
# To add a document (e.g. manuscript v3): append its directory to DOCS.

DOCS      := docs/manuscript/v2 docs/action-plan/document
MAIN      := main
IMAGE     ?= dnssec-lab-latex
DOC       ?= docs/manuscript/v2

.DEFAULT_GOAL := help
.PHONY: help all manuscript action-plan watch clean distclean docker-build docker-run $(DOCS)

help:
	@sed -n '2,12p' $(MAKEFILE_LIST) | sed 's/^# \{0,1\}//'

all: $(DOCS)

manuscript: docs/manuscript/v2
action-plan: docs/action-plan/document

# latexmk runs inside the document directory so its latexmkrc is picked up.
$(DOCS):
	cd $@ && latexmk $(MAIN).tex
	@echo "==> $@/build/$(MAIN).pdf"

watch:
	cd $(DOC) && latexmk -pvc $(MAIN).tex

clean:
	@for d in $(DOCS); do (cd $$d && latexmk -c $(MAIN).tex); done

distclean:
	@for d in $(DOCS); do (cd $$d && latexmk -C $(MAIN).tex; rm -rf build); done

docker-build:
	docker build -t $(IMAGE) .

# Runs as the host user so files in build/ are not owned by root.
docker-run:
	docker run --rm -v "$(CURDIR)":/work -u "$$(id -u):$$(id -g)" $(IMAGE) make all
