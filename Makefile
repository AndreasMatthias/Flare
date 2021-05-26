
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
	rm -f -r auto
	rm -f $(TDS-ZIP)
	$(MAKE) distclean -C test

archive-git:
	tar cjf flare.tar.bz2 .git/


VERSION=0.1
DIST-DIR:=$(shell mktemp -d -p .)
DIST-TEX-DIR=$(DIST-DIR)/tex/latex/flare/
DIST-LUA-DIR=$(DIST-TEX-DIR)
DIST-DOC-DIR=$(DIST-DIR)/doc/latex/flare/
DIST-EXP-DIR=$(DIST-DOC-DIR)/exmaples

DIST-TEX-FILES= \
	flare.sty

DIST-LUA-FILES= \
	flare-action.lua \
	flare-annot.lua \
	flare-dest.lua \
	flare-doc.lua \
	flare-format-annot.lua \
	flare-format-obj.lua \
	flare-keyval.lua \
	flare.lua \
	flare-luatex.lua \
	flare-page.lua \
	flare-pkg.lua \
	flare-types.lua

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

	cd $(DIST-DIR); zip -r $(TDS-ZIP) *
	cp $(DIST-DIR)/$(TDS-ZIP) .
	rm -r $(DIST-DIR)

	mkdir -p release/
	mv $(TDS-ZIP) release/

release: tds
