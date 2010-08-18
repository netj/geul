# Makefile for Geul publishing system
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2009-03-07

export GEUL_BINDIR  := bin
export GEUL_LIBDIR  := lib
export GEUL_CMDDIR  := libexec/geul
export GEUL_DATADIR := share/geul
export GEUL_DOCDIR  := share/doc/geul

PACKAGENAME := geul
PACKAGEVERSION := 0.9.$(shell date +%Y%m%d)
PACKAGEEXECUTES := bin/geul

include buildkit/modules.mk
buildkit/modules.mk:
	git clone http://github.com/netj/buildkit.git

