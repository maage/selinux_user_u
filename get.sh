#!/bin/bash
set -x
myfilter() {
	sed -r '
/  denied /!d;
/ (siginh|rlimitinh|noatsecure) /d;
/comm="(ps|pgrep)".*dev="proc"/d;
/\{ sys_ptrace \} .* comm="(chrome|ps|systemd-journal|MemoryInfra)" .* tclass=cap_userns /d;
	'
}

mysource() {
	journalctl --since -5m SYSLOG_IDENTIFIER=audit
}

#journalctl --since -2h SYSLOG_IDENTIFIER=audit|sed -r '/  denied /!d;/comm="(gnome-terminal-|cpan|perl|dnf)"/d'|audit2allow -r -R|egrep -v '^#|^$'
if (($#)); then
	mysource | myfilter  | audit2allow -r "$@"
	exit $?
fi
mysource | myfilter | audit2allow -r | a2a-cleanup
