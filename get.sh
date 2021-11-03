#!/bin/bash

# SPDX-FileCopyrightText: 2021 Markus Linnala <markus.linnala@cybercom.com>
#
# SPDX-License-Identifier: Apache-2.0

set -x

declare -i OPT_boot=0

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

my_cleaning_filter() {
    sed -r '
/^#  scontext=/,/^#  message=/{
    /^#  message=/!d;
    s/^#  message=" (AVC avc:)/# \1/;
}
/^# AVC avc:/,/ "$/{
    H;
    / "$/{
        g;
        s/^\n+//;
        s/\n#   / /g;
        s/ "$//;
        p;
        z;
        x;
    }
    d;
}
/^#?[[:space:]]*$/d;
    '
}

get_cursor() {
    journalctl -r --system _AUDIT_TYPE_NAME=MAC_POLICY_LOAD -o json | jq -nr 'input|.__CURSOR'
}

mysource() {
    local args=()
    if (( OPT_boot )); then
        args=(-b0)
    else
        args=(--cursor="$(get_cursor)")
    fi
    journalctl "${args[@]}" --no-hostname --quiet -g denied SYSLOG_IDENTIFIER=audit
}

myuniq() {
    cut -d: -f4- | awk '!s[$0]++'
}

while (($#)); do
    case "$1" in
        --boot) shift; OPT_boot=1 ;;
        --) shift; break ;;
        *) break ;;
    esac
done

if (($#)); then
    mysource | myuniq | myfilter | audit2allow -r "$@" | my_cleaning_filter
    exit $?
fi
mysource | myuniq | myfilter | audit2allow -r | a2a-cleanup | my_cleaning_filter
