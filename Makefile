QUIET := n

.PHONY: my-hop my-commit lines local_lines
my-hop: all
	sudo $(MAKE) load

all: my-commit

my-commit:
	@./commit.sh

include /usr/share/selinux/devel/Makefile

SEMODULE := $(SBINDIR)/semodule -v
