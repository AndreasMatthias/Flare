FLARE_FILES := \
        flare.sty \
        flare.lua \
        flare-pkg.lua \
        flare-types.lua \
        flare-doc.lua \
        flare-page.lua \
        flare-keyval.lua \
        flare-annot.lua \
        flare-dest.lua \
        flare-action.lua \
        flare-luatex.lua \
        flare-format-obj.lua \
        flare-format-annot.lua

EXAMPLES := \
	example-1.pdf \
	example-2.pdf

.PHONY: all

all: $(FLARE_FILES) $(EXAMPLES)

%.pdf: %.tex
	lualatex $<
	lualatex $<

$(FLARE_FILES):
	ln -sf ../$@


.PHONY: clean distclean
clean:
	rm -f *.log *.aux *.flr *.out *.thm
# rm -f *.{log,aux,flr,thm,out}
# rm -f $(EXAMPLES:.pdf=.log) $(EXAMPLES:.pdf=.aux)
# 	rm -f $(EXAMPLES:.pdf=.flr) $(EXAMPLES:.pdf=.thm)

distclean: clean
	rm -f $(EXAMPLES)
	rm -f $(FLARE_FILES)
