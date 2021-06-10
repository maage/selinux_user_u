QUIET := n

.PHONY: my-hop my-commit
my-hop: all
	sudo $(MAKE) load

all: my-commit

my-commit:
	./commit.sh

include /usr/share/selinux/devel/Makefile

SEMODULE := $(SBINDIR)/semodule -v

te_lines: local_lines
	if [ -d ../cil-parser ]; then \
		rm -rf ../cil-parser/local_lines; \
		mv local_lines ../cil-parser/local_lines; \
	fi

local_lines:
	./te_lines.sh
