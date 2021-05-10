QUIET := n

.PHONY: hop
hop:
	./create.sh

include /usr/share/selinux/devel/Makefile
