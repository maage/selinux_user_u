# SPDX-FileCopyrightText: 2021 Markus Linnala <markus.linnala@cybercom.com>
#
# SPDX-License-Identifier: Apache-2.0

MLSENABLED ?=
QUIET := n
verbose ?=

SELINT ?= selint
SEMOD_LNK ?= semodule_link # -v
SEMOD_EXP ?= semodule_expand
SEPOLGEN ?= sepolgen-ifgen -v
SUDO ?= sudo
base_pkg = base.pp

.PHONY: all check commit default lint validate

default: all
	$(SUDO) $(MAKE) load

all: commit

commit:
	@./commit.sh

#

include /usr/share/selinux/devel/Makefile

SEMODULE ?= $(SBINDIR)/semodule -v

# lint
# SELINT_ARGS_fc = --disable=E-005
# SELINT_ARGS_te = --disable=C-001 --disable=S-001
# SELINT_ARGS_if =
# define selint_template
# tmp/lint.$(1).flag: $$(all_packages:.pp=.$(1))
# 	@mkdir -p tmp
# 	$(SELINT) $$(SELINT_ARGS_$(1)) $$?
# 	@touch -- $$@
# lint: tmp/lint.$(1).flag
# endef
# $(foreach suf,fc if te,$(eval $(call selint_template,$(suf))))
lint:
	selint -r --context=../selinux-policy --disable={C-001,S-001,S-002,W-011} .

check: lint

# validate

$(base_pkg):
	$(verbose) $(SUDO) $(SEMODULE) --hll --extract=$(@:.pp=)
tmp/validate.lnk: $(base_pkg) $(all_packages)
	$(verbose) $(SEMOD_LNK) -o $@ $^
tmp/validate.policy.bin: tmp/validate.lnk
	$(verbose) $(SEMOD_EXP) $^ $@
tmp/validate.output: tmp/validate.policy.bin
	$(verbose) $(SEPOLGEN) --policy=$^ --interfaces=$(HEADERDIR) --output=$@
validate: tmp/validate.output

check: validate
