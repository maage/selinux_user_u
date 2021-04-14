PP := local_user_u.pp local_user_bwrap.pp local_f33_regression.pp

all: modules

modules: $(PP)

%.pp: %.te %.if %.fc
	$(MAKE) -f /usr/share/selinux/devel/Makefile QUIET=n $@
