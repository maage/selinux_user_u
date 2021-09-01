# SPDX-FileCopyrightText: 2021 Markus Linnala <markus.linnala@cybercom.com>
#
# SPDX-License-Identifier: Apache-2.0

QUIET := n

.PHONY: my-hop all my-commit
my-hop: all
	sudo $(MAKE) load

all: my-commit

my-commit:
	@./commit.sh

include /usr/share/selinux/devel/Makefile

SEMODULE := $(SBINDIR)/semodule -v
