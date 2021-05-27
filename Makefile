QUIET := n

.PHONY: my-hop my-commit
my-hop: all
	sudo $(MAKE) load

all: my-commit

my-commit:
	./commit.sh

include /usr/share/selinux/devel/Makefile

tmp/loaded: $(all_packages)
	@$(EINFO) "Loading $(NAME) modules: $(basename $(notdir $?))"
	$(verbose) $(SEMODULE) -v $(foreach mod,$?,-i $(mod))
	@mkdir -p tmp
	@touch tmp/loaded
