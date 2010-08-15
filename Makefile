# Makefile for Geul publishing system
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2009-03-07

VERSION:=0.9.$(shell date +%Y%m%d)

STAGEDIR := .stage

export GEUL_BINDIR  := bin
export GEUL_LIBDIR  := lib
export GEUL_CMDDIR  := libexec/geul
export GEUL_DATADIR := share/geul
export GEUL_DOCDIR  := share/doc/geul

include buildkit/modules.mk
buildkit/modules.mk:
	git clone http://github.com/netj/buildkit.git


### XXX clean these up
dist: $(NAME)-$(VERSION).sh
$(NAME)-$(VERSION).sh: stage ident pojang/pojang
	cd $(STAGEDIR); \
	    pojang bin/geul * >$@
	chmod +x $@
pojang/pojang:
	git clone http://github.com/netj/pojang.git


ident: Makefile .git/HEAD stage
	{ \
	echo $(NAME) $(VERSION) `git rev-parse HEAD 2>/dev/null`; \
	echo Modules:; \
	all-modules; \
	} >$@


.build/$(PRODUCT): $(SRCS)
	mkdir -p $(@D)
	eval "pojang $(SRCS)" >$@
	chmod +x $@

