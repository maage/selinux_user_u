# SPDX-FileCopyrightText: 2021 Markus Linnala <markus.linnala@cybercom.com>
#
# SPDX-License-Identifier: Apache-2.0

QUIET := n

.PHONY: default all commit lint
default: all
	sudo $(MAKE) load

all: commit

commit:
	@./commit.sh

lint:
	selint --disable=E-005 *.fc
	selint --disable=S-001 *.te
	selint *.if

include /usr/share/selinux/devel/Makefile

SEMODULE := $(SBINDIR)/semodule -v
