TEST_FILES = \
	test-flare-pkg.lua \
	test-flare-types.lua \
	test-flare-doc.lua \
	test-flare-page.lua \
	test-flare-keyval.lua \
	test-flare-format-obj1.lua \
	test-flare-format-obj2.lua \
	test-flare-format-annot1.lua \
	test-flare-format-annot2.lua \
	test-flare-format-annot3.lua \
	test-flare-dest.lua \
	test-flare-action.lua

MODULE_FILES = \
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
	flare-annot.lua \
	flare-dest.lua \
	flare-action.lua

.PHONY: test
test: $(TEST_FILES:.lua=.run)

.PHONY: coverage
coverage:
	rm -f luacov.stats.out
	$(MAKE) $(TEST_FILES:.lua=.cov)
	luacov-coveralls --dryrun -o ../coverage-final.json > /dev/null


%.run: %.tex %.lua $(MODULE_FILES)
	@echo -e '\033[1mRunning $*.lua ...\033[0m'
	lualatex --shell-escape --interaction=nonstopmode $< \
                 --exclude-tags="skip" $(TESTARGS)
	touch $@

%.cov: %.tex $(MODULE_FILES) FORCE
	lualatex --shell-escape --interaction=nonstopmode $< \
                 --exclude-tags="skip" $(TESTARGS) -lluacov

$(MODULE_FILES):
	ln -sf ../$@


.PHONY: clean distclean
clean:
	rm -f *.aux *.log
	rm -f luacov.stats.out $(TEST_FILES:.lua=.run)

distclean: clean
	rm -f -r auto
	rm -f $(MODULE_FILES)
	rm -f tmp_*

.PHONY: FORCE
FORCE:
