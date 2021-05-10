QUIET := n

.PHONY: my-hop my-create
my-hop: | my-create all
my-hop:
	sudo /usr/sbin/semodule -v -i *.pp

my-create:
	./create.sh

include /usr/share/selinux/devel/Makefile
