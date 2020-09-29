#!/bin/bash
set -x
#journalctl --since -2h SYSLOG_IDENTIFIER=audit|sed -r '/  denied /!d;/comm="(gnome-terminal-|cpan|perl|dnf)"/d'|audit2allow -r -R|egrep -v '^#|^$'
if (($#)); then
	journalctl --since -5m SYSLOG_IDENTIFIER=audit|sed -r '/  denied /!d;/ (siginh|rlimitinh|noatsecure) /d;/comm="ps".*dev="proc"/d' |audit2allow -r "$@"
	exit $?
fi
journalctl --since -5m SYSLOG_IDENTIFIER=audit|sed -r '/  denied /!d;/ (siginh|rlimitinh|noatsecure) /d;/comm="ps".*dev="proc"/d' |audit2allow -r|a2a-cleanup
