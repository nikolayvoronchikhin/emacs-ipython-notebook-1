EMACS ?= $(shell which emacs)
IPYTHON = env/ipy.$(IPY_VERSION)/bin/ipython
IPY_VERSION = 5.8.0
SRC=$(shell cask files)
ELCFILES = $(SRC:.el=.elc)

.PHONY: loaddefs
loaddefs:
	sh tools/update-autoloads.sh

.PHONY: clean
clean:
	cask clean-elc

env-ipy.%:
	tools/makeenv.sh env/ipy.$* tools/requirement-ipy.$*.txt

.PHONY: test-compile
test-compile: clean
	! ( cask build 2>&1 | awk '{if (/^ /) { gsub(/^ +/, " ", $$0); printf "%s", $$0 } else { printf "\n%s", $$0 }}' | egrep "not known|Error|free variable" )
	-cask clean-elc

.PHONY: test-no-build
test-no-build: test-unit test-int

.PHONY: test
test: test-compile test-unit test-int

.PHONY: test-int
test-int:
	cask exec ert-runner -L ./lisp -L ./test -l test/testfunc.el test/test-func.el
	cask exec ecukes

.PHONY: test-unit
test-unit:
	cask exec ert-runner -L ./lisp -L ./test -l test/testein.el test/test-ein*.el

travis-ci-zeroein:
	$(EMACS) --version
	EMACS=$(EMACS) lisp/zeroein.el -batch
	rm -rf lib/*
	EMACS=$(EMACS) lisp/zeroein.el -batch
