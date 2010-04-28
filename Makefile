# Makefile for Geul publishing system
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2009-03-07

NAME:=geul
VERSION:=0.1.$(shell date +%Y%m%d)-snapshot
PRODUCT:=$(NAME)-$(VERSION).sh

MODULES:=$(shell find * -name .module -print | sed 's:/.module$$::' | sort --ignore-case)
SRCS:= \
      geul \
      ident \
      $(shell find $(MODULES) -type f \
	  \! \( -name '.*sw?' -o -name .DS_Store \) | sed 's: :\\ :g')

.build/$(PRODUCT): $(SRCS)
	mkdir -p $(@D)
	eval "pojang $(SRCS)" >$@
	chmod +x $@

ident: Makefile .git/HEAD
	{ \
	echo $(NAME) $(VERSION) `git rev-parse HEAD 2>/dev/null`; \
	echo Modules: $(MODULES); \
	} >$@


.PHONY: all install clean distclean
all install: .build/$(PRODUCT)
install:
	install $< ~/bin/$(NAME)
clean:
	rm -f .build/$(PRODUCT)
distclean:
	rm -rf .build
