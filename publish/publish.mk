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

LEAVE_INTERMEDIATES ?= true
ifeq ($(LEAVE_INTERMEDIATES),true)
.SECONDARY:
endif


## resources
.SECONDEXPANSION:
%:: $(GEUL_DIR)/resources/$$@
	$(progress)
	mkdir -p $(@D)
	install -m a+r-w $< $@
.SECONDEXPANSION:
%:: $(GEUL_DIR)/resources/$$@,v
	$(progress)
	save-output $@ geul-show $*


## chrome
chromexsl:=$(GEUL_DIR)/chrome.xsl
ifeq ($(shell test -e "$(chromexsl)" || echo false),)
    define chrome
	save-output $@ xslt "$(chromexsl)" $<
    endef
else
    chromexsl:=
    define chrome
	ln -f $< $@
    endef
endif

%.html: %.xhtml $(chromexsl) %.indexed
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
# TODO: clean up extension names
%.xhtml: %.xhtml-plain $(article_xsl) %.atom
	save-output $@ xslt "$(article_xsl)" $< \
	    --param Id "'$*'" \
	    $${GEUL_BASEURL:+--param BaseURL "'$$GEUL_BASEURL'"}
%.xhtml-plain: %.xhtml-head %.geul
	save-output $@ text2xhtml $^
%.xhtml-head: %.meta %.log
	save-output $@ meta2xhtml-head $* $^

%.summary: %.meta %.geul
	save-output $@ text2summary $^
%.meta: %.geul %.log
	save-output $@ text2meta $* $^
%.log: %.geul
	-geul-log $< >$@
#	save-output $@ geul-log $*

# See http://www.gnu.org/software/make/manual/make.html#Multiple-Rules
# xhtml-based
%.summary: %.meta %.xhtml
	# TODO
	echo XXX $@: $^ >&2
	touch -r $< $@
%.meta: %.xhtml
	# TODO
	echo XXX $@: $^ >&2
	touch -r $< $@


## indexing
%.indexed: %.meta %.summary
	geul-index add $^
	touch $@


## feed
%.atom: %.meta
	if grep -qi ^Feed-Method: $<; then \
	    $(progress); \
	    save-output $@ feed2atom $* $^; \
	fi

atom2json_xsl:=$(GEUL_BASE)/publish/atom2json.xsl
%.json: %.atom
	$(progress)
	save-output $@ xslt "$(atom2json_xsl)" $<

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
