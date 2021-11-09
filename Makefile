# SPDX-FileCopyrightText: 2021 Markus Linnala <markus.linnala@cybercom.com>
#
# SPDX-License-Identifier: Apache-2.0

QUIET := n

SEMOD_LNK ?= semodule_link # -v
SEMOD_EXP ?= semodule_expand
SEPOLGEN ?= sepolgen-ifgen -v
base_pkg = base.pp

.PHONY: all check commit default lint validate

default: all
	sudo $(MAKE) load

all: commit

commit:
	@./commit.sh

#

include /usr/share/selinux/devel/Makefile

SEMODULE ?= $(SBINDIR)/semodule -v

# lint

tmp/lint.fc.flag: $(all_packages:.pp=.fc)
	selint --disable=E-005 $?
	@touch -- $@
lint: tmp/lint.fc.flag
tmp/lint.te.flag: $(all_packages:.pp=.te)
	selint --disable=S-001 $?
	@touch -- $@
lint: tmp/lint.te.flag
tmp/lint.if.flag: $(all_packages:.pp=.if)
	selint $?
	@touch -- $@
lint: tmp/lint.if.flag

check: lint

# validate

$(base_pkg):
	sudo $(SEMODULE) --hll --extract=$(@:.pp=)
tmp/validate.lnk: $(base_pkg) $(all_packages)
	$(verbose) $(SEMOD_LNK) -o $@ $^
tmp/validate.policy.bin: tmp/validate.lnk
	$(verbose) $(SEMOD_EXP) $^ $@
tmp/validate.output: tmp/validate.policy.bin
	$(verbose) $(SEPOLGEN) --policy=$^ --interfaces=$(HEADERDIR) --output=$@
validate: tmp/validate.output

check: validate
