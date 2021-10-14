# SPDX-FileCopyrightText: 2021 Markus Linnala <markus.linnala@cybercom.com>
#
# SPDX-License-Identifier: Apache-2.0

QUIET := n

.PHONY: my-hop all my-commit lint
my-hop: all
	sudo $(MAKE) load

all: my-commit

my-commit:
	@./commit.sh

lint:
	selint --disable=E-005 *.fc
	selint --disable=S-001 *.te
	selint *.if

include /usr/share/selinux/devel/Makefile

SEMODULE := $(SBINDIR)/semodule -v
