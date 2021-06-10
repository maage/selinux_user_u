#!/bin/bash

set -epux -o pipefail

rm -rf module_lines
mkdir -p module_lines

for a in *.te;do
	cnt=0
	requires="$(sed -n '/^[[:space:]]*require {/,/^[[:space:]]*}/{/^[[:space:]]*require {/d;/^[[:space:]]*}/d;/^[[:space:]]*#/d;s/^[[:space:]]*//;p}' "$a"|sort -u)"
	while read -r line; do
		printf "policy_module(%s_%d, 1.0.0)\nrequire {\n%s\n}\n%s\n" "${a%.te}" $cnt "$requires" "$line" > module_lines/"${a%.te}"_"$cnt".te
		(( cnt++ )) || :
	done < <(sed -n '/^policy_module(/d;/^[[:space:]]*require {/,/^[[:space:]]*}/d;/^[[:space:]]*#/d;/^$/d;/^tunable_policy/d;/^optional_policy/d;/^'"'"')/d;p' "$a")
done
