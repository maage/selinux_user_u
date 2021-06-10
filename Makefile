QUIET := n

.PHONY: my-hop my-commit
my-hop: all
	sudo $(MAKE) load

all: my-commit

my-commit:
	./commit.sh

include /usr/share/selinux/devel/Makefile

SEMODULE := $(SBINDIR)/semodule -v

module_lines: $(3rd_party_mods)
	./te_lines.sh
