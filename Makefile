QUIET := n

.PHONY: my-hop my-commit
my-hop: all
	sudo $(MAKE) load

all: my-commit

my-commit:
	./commit.sh

SEMODULE := $(SBINDIR)/semodule -v

include /usr/share/selinux/devel/Makefile
