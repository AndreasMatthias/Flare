
.PHONY: doc
doc:
	$(MAKE) $@ -C doc

.PHONY: test
test:
	$(MAKE) $@ -C test
coverage:
	$(MAKE) $@ -C test


.PHONY: clean distclean
clean:
	rm -f *.log *.aux
	rm -f coverage-final.json
	$(MAKE) clean -C test 

distclean: clean
	rm -f -r auto release
	rm -f $(TDS-ZIP)
	$(MAKE) distclean -C test


GIT_SHA:=$(shell git log --pretty=format:"%H" -1)
GIT_SHA_SHORT:=$(shell git log --pretty=format:"%h" -1)
GIT_DATE:=$(shell git log --pretty=format:"%cs" -1)

DIST-DIR=release/tmp
DIST-TEX-DIR=$(DIST-DIR)/tex/latex/flare/
DIST-LUA-DIR=$(DIST-TEX-DIR)
DIST-DOC-DIR=$(DIST-DIR)/doc/latex/flare/
DIST-EXP-DIR=$(DIST-DOC-DIR)/exmaples

DIST-TEX-FILES= \
	flare.sty

DIST-LUA-FILES= \
	flare.lua \
	flare-pkg.lua \
	flare-types.lua \
	flare-luatex.lua \
	flare-doc.lua \
	flare-page.lua \
	flare-keyval.lua \
	flare-obj.lua \
	flare-annot.lua \
	flare-dest.lua \
	flare-action.lua

DIST-DOC-FILES= \
	README.md

DIST-EXP-FILES=\
	./examples/dummy-1.pdf \
	./examples/dummy-2.pdf \
	./examples/example-1.tex \
	./examples/example-2.tex

TDS-ZIP=flare.tds.zip

.PHONY: tds
tds:
	mkdir -p $(DIST-TEX-DIR)
	mkdir -p $(DIST-LUA-DIR)
	mkdir -p $(DIST-DOC-DIR)
	mkdir -p $(DIST-EXP-DIR)
	cp $(DIST-TEX-FILES) $(DIST-TEX-DIR)
	cp $(DIST-LUA-FILES) $(DIST-LUA-DIR)
	cp $(DIST-DOC-FILES) $(DIST-DOC-DIR)
	cp $(DIST-EXP-FILES) $(DIST-EXP-DIR)

	lua5.3 ./.travis/update-metadata.lua $(DIST-TEX-DIR)/flare.sty

	cd $(DIST-DIR); zip -r $(TDS-ZIP) *
	cp $(DIST-DIR)/$(TDS-ZIP) .
	rm -r $(DIST-DIR)

release: tds
