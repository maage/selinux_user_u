#!/bin/sh

set -epux -o pipefail
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
