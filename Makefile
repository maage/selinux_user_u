QUIET := n

.PHONY: my-hop my-commit
my-hop: | my-commit
my-hop: all load

my-commit:
	./commit.sh

include /usr/share/selinux/devel/Makefile
