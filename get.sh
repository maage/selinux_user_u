#!/bin/bash

# SPDX-FileCopyrightText: 2021 Markus Linnala <markus.linnala@cybercom.com>
#
# SPDX-License-Identifier: Apache-2.0

set -x
myfilter() {
    sed -r '
/  denied /!d;
/ (siginh|rlimitinh|noatsecure) /d;
/ comm="(ps|pgrep)" /{/ dev="proc" /d};
/ \{ sys_ptrace \} /{/ comm="(chrome|ps|systemd-journal|MemoryInfra)" /{/ tclass=cap_userns /d}};
/ comm="less" /{/ scontext=[^:]*:[^:]*:journalctl_t:/{
    / \{ getattr \} /{/ path="[/]dev[/][^"]*" dev="(devtmpfs|devpts|hugetlbfs)" /d};
    / \{ getattr \} /{/ tcontext=system_u:object_r:(initctl_t|proc_kcore_t):/d};
    / \{ search \} /{/ name="[/]" dev="devpts" /d};
}}
    '
}

get_cursor() {
    journalctl -r --system _AUDIT_TYPE_NAME=MAC_POLICY_LOAD -o json | jq -nr 'input|.__CURSOR'
}

mysource() {
    journalctl --cursor="$(get_cursor)" --no-hostname --quiet -g denied SYSLOG_IDENTIFIER=audit
    # journalctl --since -5m -g denied SYSLOG_IDENTIFIER=audit
    # journalctl -b0 -g denied SYSLOG_IDENTIFIER=audit
}

myuniq() {
    cut -d: -f4- | awk '!s[$0]++'
}

#journalctl --since -2h SYSLOG_IDENTIFIER=audit|sed -r '/  denied /!d;/comm="(gnome-terminal-|cpan|perl|dnf)"/d'|audit2allow -r -R|egrep -v '^#|^$'
if (($#)); then
    mysource | myuniq | myfilter | audit2allow -r "$@"
    exit $?
fi
mysource | myuniq | myfilter | audit2allow -r | a2a-cleanup
