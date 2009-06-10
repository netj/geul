#!/usr/bin/make -f
# publish.mk -- Makefile for publishing rules of Geul
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2009-06-03
SHELL:=$(shell which bash)

GEUL_DIR ?= .geul

SHOW_PROGRESS ?= false
ifeq ($(SHOW_PROGRESS),true)
    progress=echo $@
else
    progress=
endif

LEAVE_INTERMEDIATES ?= false
ifeq ($(LEAVE_INTERMEDIATES),true)
.SECONDARY:
endif

## external resources
chromexsl:=$(GEUL_DIR)/chrome.xsl
ifeq ($(shell test -e "$(chromexsl)" || echo false),)
%.html: %.xhtml $(chromexsl)
	$(progress)
	xslt "$(chromexsl)" $< $@
	touch -r $< $@
else
%.html: %.xhtml
	$(progress)
	ln -f $< $@
endif

# custom chrome resources
chrome/%:: $(GEUL_DIR)/chrome/%
	$(progress)
	mkdir -p $(@D)
	ln -f $< $@

# base chrome resources
chrome/%:: $(GEULBASE)/publish/chrome/%
	$(progress)
	mkdir -p $(@D)
	install -m +r-wx $< $@

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


## internal resources
T:=.geul.

articlexsl:=$(GEULBASE)/publish/article.xsl
%.xhtml: $T%.xhtml $(articlexsl)
	$(progress)
	xslt "$(articlexsl)" $< $@ \
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
