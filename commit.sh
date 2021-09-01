#!/bin/sh

# SPDX-FileCopyrightText: 2021 Markus Linnala <markus.linnala@cybercom.com>
#
# SPDX-License-Identifier: Apache-2.0

set -epu -o pipefail
rc=0
git status --porcelain | grep -Eq '^' || rc=$?
if [ $rc -eq 0 ]; then
        git add -u
        git commit -m hop
elif [ $rc -eq 1 ]; then
        :
else
        echo "RC=$?"
        exit $?
fi
