# Makefile for Geul publishing system
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2009-03-07

NAME:=geul
VERSION:=1.$(shell date +%Y%m%d)-snapshot
PRODUCT:=$(NAME)-$(VERSION).sh

MODULES:=$(shell find * -name .module -print | sed 's:/.module$$::')
SRCS:= \
      geul \
      ident \
      $(shell find $(MODULES) -type f \
          \! \( -name '.*sw?' -o -name .DS_Store \))

dist/$(PRODUCT): $(SRCS)
	mkdir -p $(@D)
	pojang $^ >$@
	chmod +x $@

ident: Makefile .git/HEAD
	{ \
	echo $(NAME) $(VERSION) `git rev-parse HEAD 2>/dev/null`; \
	echo Modules: $(MODULES); \
	} >$@


.PHONY: all install clean distclean
all install: dist/$(PRODUCT)
install:
	install $< ~/bin/$(NAME)
clean:
	rm -f dist/$(PRODUCT)
distclean:
	rm -rf dist
