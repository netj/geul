# Makefile for testing map
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2009-09-08

TESTCASES=$(shell find * -name \*.input)
TEST=../map test.db

tests: $(TESTCASES:%.input=%.tested)

%.tested: %.expected %.actual
	diff -Nu $^ | tee $@

%.actual: %.input
	$(TEST) <$< >$@

clean:
	rm -f test.db *.actual *.tested
