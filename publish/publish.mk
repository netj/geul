#!/usr/bin/make -f
# publish.mk -- Makefile for publishing rules of Geul
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2009-06-03
SHELL:=$(shell which bash)

GEUL_DIR ?= .geul
GEUL_STAGE ?= $(GEUL_DIR)/stage

SHOW_PROGRESS ?= false
ifeq ($(SHOW_PROGRESS),true)
    progress=echo $(@:$(GEUL_STAGE)/%=%)
else
    progress=
endif

LEAVE_INTERMEDIATES ?= true
ifeq ($(LEAVE_INTERMEDIATES),true)
.SECONDARY:
endif


## resources
$(GEUL_STAGE)/%: %
	$(progress)
	mkdir -p $(@D)
	if [ -L $< ]; then \
	    ln -sfn "`readlink "$<"`" "$@"; \
	else \
	    install -m a+r-w $< $@; \
	fi


## HTML5 final output
xhtml2html5xsl := $(GEUL_DATADIR)/publish/xhtml2html5.xsl
$(GEUL_STAGE)/%.html: $(GEUL_STAGE)/%.xhtml $(xhtml2html5xsl)
	$(progress)
	save-output $@ xslt "$(xhtml2html5xsl)" $<


## chrome
chromexsl:=$(GEUL_DIR)/chrome.xsl
ifeq ($(shell test -e "$(chromexsl)" || echo false),)
    define chrome
	save-output $@ xslt "$(chromexsl)" $< \
	    $${GEUL_BASEURL:+BaseURL="$$GEUL_BASEURL"}
    endef
else
    chromexsl:=
    define chrome
	ln -f $< $@
    endef
endif
$(GEUL_STAGE)/%.xhtml: $(GEUL_STAGE)/%.xhtml-plain $(chromexsl) $(GEUL_STAGE)/%.indexed
	$(progress)
	$(chrome)

$(GEUL_STAGE)/chrome/%:: $(GEUL_DATADIR)/publish/chrome/%
	$(progress)
	mkdir -p $(@D)
	install -m +r-wx $< $@


## article
# text-based
article_xsl:=$(GEUL_DATADIR)/publish/article.xsl
# TODO: clean up extension names
$(GEUL_STAGE)/%.xhtml-plain: $(GEUL_STAGE)/%.xhtml-raw $(GEUL_STAGE)/%.atom $(GEUL_DIR)/base-url $(article_xsl)
	$(progress)
	save-output $@ xslt "$(article_xsl)" $< \
	    Id="$*" \
	    $${GEUL_BASEURL:+BaseURL="$$GEUL_BASEURL"}
$(GEUL_STAGE)/%.xhtml-raw: $(GEUL_STAGE)/%.xhtml-head $(GEUL_STAGE)/%.geul
	$(progress)
	save-output $@ text2xhtml $^
$(GEUL_STAGE)/%.xhtml-head: $(GEUL_STAGE)/%.meta $(GEUL_STAGE)/%.log
	$(progress)
	save-output $@ meta2xhtml-head $* $^

$(GEUL_STAGE)/%.summary: $(GEUL_STAGE)/%.meta $(GEUL_STAGE)/%.geul  $(GEUL_CMDDIR)/publish/text2summary
	$(progress)
	save-output $@ text2summary $(GEUL_STAGE)/$*.meta $(GEUL_STAGE)/$*.geul
$(GEUL_STAGE)/%.meta: $(GEUL_STAGE)/%.geul $(GEUL_STAGE)/%.log  $(GEUL_CMDDIR)/publish/text2meta
	$(progress)
	save-output $@ text2meta $* $(GEUL_STAGE)/$*.geul $(GEUL_STAGE)/$*.log
$(GEUL_STAGE)/%.log: $(GEUL_STAGE)/%.geul
	$(progress)
	save-output $@ geul-log $*.geul

# See http://www.gnu.org/software/make/manual/make.html#Multiple-Rules
# xhtml-based
$(GEUL_STAGE)/%.summary: $(GEUL_STAGE)/%.meta $(GEUL_STAGE)/%.xhtml
	$(progress)
	# TODO
	echo XXX $@: $^ >&2
	touch -r $< $@
$(GEUL_STAGE)/%.meta: $(GEUL_STAGE)/%.xhtml
	$(progress)
	# TODO
	echo XXX $@: $^ >&2
	touch -r $< $@


## indexing
$(GEUL_STAGE)/%.indexed: $(GEUL_STAGE)/%.meta $(GEUL_STAGE)/%.summary $(GEUL_STAGE)/%.xhtml-raw
	$(progress)
	geul-index add $^
	touch $@


## feed
$(GEUL_STAGE)/%.atom: $(GEUL_STAGE)/%.meta $(GEUL_STAGE)/%.indexed
	if grep -qi ^Feed-Method: $<; then \
	    $(progress); \
	    save-output $@ feed2atom $* $^; \
	fi

atom2json_xsl:=$(GEUL_DATADIR)/publish/atom2json.xsl
$(GEUL_STAGE)/%.json: $(GEUL_STAGE)/%.atom $(atom2json_xsl)
	$(progress)
	save-output $@ xslt "$(atom2json_xsl)" $<

## miscellanea
$(GEUL_STAGE)/.htaccess:: $(GEUL_DATADIR)/publish/htaccess
	$(progress)
	cat $^ >$@

$(GEUL_STAGE)/.htaccess:: .htaccess $(GEUL_DATADIR)/publish/htaccess
	if ! cat $^ | diff -q - $@ &>/dev/null; then \
	    $(progress); \
	    cat $^ >$@; \
	fi

