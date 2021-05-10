QUIET := n

.PHONY: my-hop my-commit
my-hop: | my-commit all
my-hop:
	sudo /usr/sbin/semodule -v -i *.pp

my-commit:
	./commit.sh

include /usr/share/selinux/devel/Makefile
