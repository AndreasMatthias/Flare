FLARE_FILES := \
        flare.sty \
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

DOC_FILES := \
	l3pdffield-checkbox.pdf

EXAMPLES := \
	example-1.pdf \
	example-2.pdf \
	example-3.pdf

.PHONY: all

all: $(FLARE_FILES) $(DOC_FILES) $(EXAMPLES)

%.pdf: %.tex
	lualatex $<
	lualatex $<

$(FLARE_FILES):
	ln -sf ../$@

$(DOC_FILES):
	ln -sf $(shell kpsewhich -format=doc $@ | head -n 1)

.PHONY: clean distclean
clean:
	rm -f *.log *.aux *.flr *.out *.thm
	rm -f $(DOC_FILES)

distclean: clean
	rm -f $(EXAMPLES)
	rm -f $(FLARE_FILES)
