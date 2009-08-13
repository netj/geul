#!/usr/bin/make -f
# publish.mk -- Makefile for publishing rules of Geul
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2009-06-03
SHELL:=$(shell which bash)

GEUL_DIR ?= .geul
T := .geul.

SHOW_PROGRESS ?= false
ifeq ($(SHOW_PROGRESS),true)
    progress=echo $@
else
    progress=
endif

LEAVE_INTERMEDIATES ?= true
ifeq ($(LEAVE_INTERMEDIATES),true)
.SECONDARY:
endif

## chrome
chromexsl:=$(GEUL_DIR)/chrome.xsl
ifeq ($(shell test -e "$(chromexsl)" || echo false),)
    define chrome
	xslt "$(chromexsl)" $< $@
	touch -r $< $@
    endef
else
    chromexsl:=
    define chrome
	ln -f $< $@
    endef
endif

%.html: %.xhtml $(chromexsl)
	$(progress)
	$(chrome)

chrome/%:: $(GEUL_DIR)/chrome/%
	$(progress)
	mkdir -p $(@D)
	ln -f $< $@

chrome/%:: $(GEUL_BASE)/publish/chrome/%
	$(progress)
	mkdir -p $(@D)
	install -m +r-wx $< $@


## article
# text-based
article_xsl:=$(GEUL_BASE)/publish/article.xsl
%.xhtml: $T%.xhtml $(article_xsl) %.atom
	$(progress)
	xslt "$(article_xsl)" $< $@ \
	    --param ArticleId "'$*'" \
	    $${GEUL_BASEURL:+--param BaseURL "'$$GEUL_BASEURL'"}
	touch -r $*.txt $@
$T%.xhtml: $T%.xhtml-head %.txt
	save-output $@ text2xhtml $^
$T%.xhtml-head: $T%.meta $T%.log
	save-output $@ meta2xhtml-head $* $^

$T%.summary: $T%.meta %.txt
	save-output $@ text2summary $^
$T%.meta: %.txt $T%.log
	save-output $@ text2meta $* $^
$T%.log: %.txt
	save-output $@ geul-log $*

.SECONDEXPANSION:
%:: $(GEUL_DIR)/archive/$$@,v
	$(progress)
	save-output $@ geul-show $*
	touch -r $< $@

# See http://www.gnu.org/software/make/manual/make.html#Multiple-Rules
# xhtml-based
$T%.summary: $T%.meta %.xhtml
	# TODO
	echo XXX $@: $^ >&2
	touch -r $< $@
$T%.meta:: %.xhtml
	# TODO
	echo XXX $@: $^ >&2
	touch -r $< $@


## feed
.PHONY: %.atom
%.atom: $T%.meta
	if grep -qi ^Feed-Method: $<; then \
	    $(progress); \
	    save-output $@ feed2atom $* $^; \
	fi

$T%.atom-entry: $T%.meta $T%.summary
	save-output $@ meta2atom-entry $^

## miscellanea
.PHONY: .htaccess
.htaccess:
	$(progress)
	f="$(GEUL_BASE)/publish/htaccess"; \
	if grep "# Begin of Geul Configuration" $@ &>/dev/null; \
	then screen -Dm vim -n $@ \
	    +"/# Begin of Geul Configuration" \
	    +"norm V/# End of Geul Configurations" \
	    +"r $$f" +"norm -dd" \
	    +wq; \
	else cat "$$f" >>$@; \
	fi


