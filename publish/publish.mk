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
	install -m a+r-w $< $@
$(GEUL_STAGE)/%: %,v
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

$(GEUL_STAGE)/%.html: $(GEUL_STAGE)/%.xhtml $(chromexsl) $(GEUL_STAGE)/%.indexed
	$(progress)
	$(chrome)

$(GEUL_STAGE)/chrome/%:: $(GEUL_BASE)/publish/chrome/%
	$(progress)
	mkdir -p $(@D)
	install -m +r-wx $< $@


## article
# text-based
article_xsl:=$(GEUL_BASE)/publish/article.xsl
# TODO: clean up extension names
$(GEUL_STAGE)/%.xhtml: $(GEUL_STAGE)/%.xhtml-plain $(GEUL_STAGE)/%.atom $(article_xsl) $(GEUL_DIR)/base-url
	save-output $@ xslt "$(article_xsl)" $< \
	    --param Id "'$*'" \
	    $${GEUL_BASEURL:+--param BaseURL "'$$GEUL_BASEURL'"}
$(GEUL_STAGE)/%.xhtml-plain: $(GEUL_STAGE)/%.xhtml-head $(GEUL_STAGE)/%.geul
	save-output $@ text2xhtml $^
$(GEUL_STAGE)/%.xhtml-head: $(GEUL_STAGE)/%.meta $(GEUL_STAGE)/%.log
	save-output $@ meta2xhtml-head $* $^

$(GEUL_STAGE)/%.summary: $(GEUL_STAGE)/%.meta $(GEUL_STAGE)/%.geul
	save-output $@ text2summary $^
$(GEUL_STAGE)/%.meta: $(GEUL_STAGE)/%.geul $(GEUL_STAGE)/%.log
	save-output $@ text2meta $* $^
$(GEUL_STAGE)/%.log: $(GEUL_STAGE)/%.geul
	-geul-log $< >$@
#	save-output $@ geul-log $*

# See http://www.gnu.org/software/make/manual/make.html#Multiple-Rules
# xhtml-based
$(GEUL_STAGE)/%.summary: $(GEUL_STAGE)/%.meta $(GEUL_STAGE)/%.xhtml
	# TODO
	echo XXX $@: $^ >&2
	touch -r $< $@
$(GEUL_STAGE)/%.meta: $(GEUL_STAGE)/%.xhtml
	# TODO
	echo XXX $@: $^ >&2
	touch -r $< $@


## indexing
$(GEUL_STAGE)/%.indexed: $(GEUL_STAGE)/%.meta $(GEUL_STAGE)/%.summary
	geul-index add $^
	touch $@


## feed
$(GEUL_STAGE)/%.atom: $(GEUL_STAGE)/%.meta
	if grep -qi ^Feed-Method: $<; then \
	    $(progress); \
	    save-output $@ feed2atom $* $^; \
	fi

atom2json_xsl:=$(GEUL_BASE)/publish/atom2json.xsl
$(GEUL_STAGE)/%.json: $(GEUL_STAGE)/%.atom
	$(progress)
	save-output $@ xslt "$(atom2json_xsl)" $<

## miscellanea
tag=of Geul Configuration
begin=^\# Begin $(tag)$
end=^\# End $(tag)$
.PHONY: $(GEUL_STAGE)/.htaccess
$(GEUL_STAGE)/.htaccess:
	f="$(GEUL_BASE)/publish/htaccess"; \
	if [ -e $@ ]; then \
	    s1=`sed -n "/$(begin)/,/$(end)/p" <$@ | md5sum`; \
	    s2=`md5sum <"$$f"`; \
	    if [ x"$$s1" != x"$$s2" ]; then \
		$(progress); \
		screen -Dm vim -n $@ \
		+"/$(begin)" \
		+"norm V/$(end)s" \
		+"r $$f" +"norm -dd" \
		+wq; \
	    fi; \
	else \
	    $(progress); \
	    cat "$$f" >>$@; \
	fi
