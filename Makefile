# Build entry point for every LaTeX document in this repository.
#
#   make                 show this help
#   make all             build the shared documents (manuscript v2 + action-plan template)
#   make manuscript      build docs/manuscript/v2
#   make template        build docs/action-plan/template
#   make personal        build every personal/<name>/ that has a main.tex
#   make new-plan NAME=<slug> [AUTHOR="Full Name" ID=A0XXXXXXX]
#                        create personal/<slug>/ from the action-plan template
#   make watch DOC=personal/<slug>     rebuild on every save
#   make clean           remove auxiliary files (keeps the PDFs)
#   make distclean       remove every build/ directory
#   make docker-build    build the image; make docker-run [TARGET=personal]
#
# Each document owns a latexmkrc; all artifacts (PDF included) go to <doc>/build/.
# personal/ is git-ignored: personal plans are local to each team member.
# To add a shared document (e.g. manuscript v3): append its directory to DOCS.

DOCS      := docs/manuscript/v2 docs/action-plan/template
PERSONAL  := $(patsubst %/main.tex,%,$(wildcard personal/*/main.tex))
TEMPLATE  := docs/action-plan/template
MAIN      := main
IMAGE     ?= dnssec-lab-latex
TARGET    ?= all
DOC       ?= docs/manuscript/v2

.DEFAULT_GOAL := help
.PHONY: help all manuscript template personal new-plan watch clean distclean \
        docker-build docker-run $(DOCS) $(PERSONAL)

help:
	@sed -n '2,16p' $(MAKEFILE_LIST) | sed 's/^# \{0,1\}//'

all: $(DOCS)

manuscript: docs/manuscript/v2
template: $(TEMPLATE)

personal:
ifeq ($(strip $(PERSONAL)),)
	@echo "No personal plans found. Create one with: make new-plan NAME=<slug>"
else
	@$(MAKE) --no-print-directory $(PERSONAL)
endif

# latexmk runs inside the document directory so its latexmkrc is picked up.
$(DOCS) $(PERSONAL):
	cd $@ && latexmk $(MAIN).tex
	@echo "==> $@/build/$(MAIN).pdf"

# Copy the template to personal/<NAME>/ (never overwrites an existing plan).
new-plan:
	@test -n "$(NAME)" || { echo "usage: make new-plan NAME=<slug> [AUTHOR=\"Full Name\" ID=A0XXXXXXX]" >&2; exit 2; }
	@echo "$(NAME)" | grep -Eq '^[A-Za-z0-9_-]+$$' || { echo "NAME must match [A-Za-z0-9_-]+ (got '$(NAME)')" >&2; exit 2; }
	@test ! -e personal/$(NAME) || { echo "personal/$(NAME) already exists; refusing to overwrite" >&2; exit 1; }
	@mkdir -p personal/$(NAME)
	@cp -R $(TEMPLATE)/main.tex $(TEMPLATE)/latexmkrc $(TEMPLATE)/sections $(TEMPLATE)/figures $(TEMPLATE)/tables personal/$(NAME)/
	@if [ -n "$(AUTHOR)" ]; then \
	    AUTHOR='$(AUTHOR)' perl -pi -e 's/(\\newcommand\{\\authorname\}\{)[^}]*(\})/$$1$$ENV{AUTHOR}$$2/' personal/$(NAME)/main.tex; fi
	@if [ -n "$(ID)" ]; then \
	    ID='$(ID)' perl -pi -e 's/(\\newcommand\{\\authorid\}\{)[^}]*(\})/$$1$$ENV{ID}$$2/' personal/$(NAME)/main.tex; fi
	@echo "Created personal/$(NAME)/  ->  build with: make personal   (or cd personal/$(NAME) && latexmk)"

watch:
	cd $(DOC) && latexmk -pvc $(MAIN).tex

clean:
	@for d in $(DOCS) $(PERSONAL); do (cd $$d && latexmk -c $(MAIN).tex); done

distclean:
	@for d in $(DOCS) $(PERSONAL); do (cd $$d && latexmk -C $(MAIN).tex; rm -rf build); done

docker-build:
	docker build -t $(IMAGE) .

# Runs as the host user so files in build/ are not owned by root.
docker-run:
	docker run --rm -v "$(CURDIR)":/work -u "$$(id -u):$$(id -g)" $(IMAGE) make $(TARGET)
