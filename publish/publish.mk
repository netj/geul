#!/usr/bin/make -f
# publish.mk -- Makefile for publishing rules of Geul
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2009-06-03
SHELL:=$(shell which bash)

GEUL_DIR ?= .geul

## external resources
chromexsl:=$(GEUL_DIR)/chrome.xsl
ifeq ($(shell test -e "$(chromexsl)" || echo false),)
%.html: %.xhtml $(chromexsl)
	echo "$@"
	xslt "$(chromexsl)" $< $@
else
%.html: %.xhtml
	echo "$@"
	ln -f $< $@
endif

# custom chrome resources
chrome/%:: $(GEUL_DIR)/chrome/%
	echo "$@"
	mkdir -p $(@D)
	ln -f $< $@

# base chrome resources
chrome/%:: $(GEULBASE)/publish/chrome/%
	echo "$@"
	mkdir -p $(@D)
	install -m +r-wx $< $@


## internal resources
.SECONDARY:
articlexsl:=$(GEULBASE)/publish/article.xsl
%.xhtml: %.xml $(articlexsl)
	echo "$@"
	xslt "$(articlexsl)" "$<" "$@" \
	    --param ArticleId "'$*'" \
	    $${GEUL_BASEURL:+--param BaseURL "'$$GEUL_BASEURL'"}

%.xml: %.txt
	echo "$@"
	# FIXME make use of $<
	save-output "$@" geul-xml "$*"

.SECONDEXPANSION:
%.txt: $(GEUL_DIR)/archive/$$(@),v
	echo "$@"
	mkdir -p "$(*D)"
	save-output "$@" geul-text "$*"

.PHONY: .htaccess
.htaccess:
	echo "$@"
	f="$(GEULBASE)/publish/htaccess"; \
	if grep "# Begin of Geul Configuration" $@ &>/dev/null; \
	then screen -Dm vim $@ \
	    +"/# Begin of Geul Configuration" \
	    +"norm V/# End of Geul Configurations" \
	    +"r $$f" +"norm -dd" \
	    +wq; \
	else cat "$$f" >>$@; \
	fi
