QUIET := n

.PHONY: my-hop my-commit
my-hop: all
	sudo $(MAKE) load

all: my-commit

my-commit:
	rpm -q --quiet gawk || sudo dnf install gawk
	./commit.sh

include /usr/share/selinux/devel/Makefile

SEMODULE := $(SBINDIR)/semodule -v
