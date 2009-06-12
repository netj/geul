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

chrome/%:: $(GEULBASE)/publish/chrome/%
	$(progress)
	mkdir -p $(@D)
	install -m +r-wx $< $@


## article
article_xsl:=$(GEULBASE)/publish/article.xsl
%.xhtml: $T%.xhtml $(article_xsl) %.atom
	$(progress)
	xslt "$(article_xsl)" $< $@ \
	    --param ArticleId "'$*'" \
	    $${GEUL_BASEURL:+--param BaseURL "'$$GEUL_BASEURL'"}
	touch -r $*.txt $@

$T%.xhtml: $T%.xhtml-head $T%.text-body
	save-output $@ text2xhtml $^
$T%.xhtml-head: $T%.meta $T%.log
	save-output $@ meta2xhtml-head $* $^
$T%.meta: $T%.text-head $T%.log
	save-output $@ text-head2meta $* $^

$T%.text-head: %.txt
	save-output $@ hd <$<
$T%.text-body: %.txt
	save-output $@ tl <$<


$T%.log: %.txt
	save-output $@ geul-log $*

.SECONDEXPANSION:
%.txt: $(GEUL_DIR)/archive/$$@,v
	$(progress)
	save-output $@ geul-show $*
	touch -r $< $@

## feed

# TODO
#calendar_index_xsl:=$(GEULBASE)/publish/index-calendar.xsl
#%.xhtml: %.atom %.month
#	$(progress)
#	xslt "$(calendar_index_xsl)" $< $@

.PHONY: %.atom
%.atom: %.feed $T%.meta
	$(progress)
	save-output $@ feed2atom $* $^
%.atom: ;

$T%.atom-entry: $T%.meta $T%.summary $T%.text-body
	save-output $@ text2atom-entry $^

$T%.summary: $T%.meta $T%.text-body
	save-output $@ text2summary $^

## miscellanea
.PHONY: .htaccess
.htaccess:
	$(progress)
	f="$(GEULBASE)/publish/htaccess"; \
	if grep "# Begin of Geul Configuration" $@ &>/dev/null; \
	then screen -Dm vim $@ \
	    +"/# Begin of Geul Configuration" \
	    +"norm V/# End of Geul Configurations" \
	    +"r $$f" +"norm -dd" \
	    +wq; \
	else cat "$$f" >>$@; \
	fi


