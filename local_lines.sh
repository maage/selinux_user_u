#!/bin/bash

set -epu -o pipefail

rm -rf local_lines
mkdir -p local_lines

for a in *.te;do
	cnt=0
	sed -n '/^[[:space:]]*require {/,/^[[:space:]]*}/{/^[[:space:]]*require {/d;/^[[:space:]]*}/d;/^[[:space:]]*#/d;s/^[[:space:]]*//;s/[[:space:]]*#.*//;p}' "$a"|sort -u > local_lines/requires.txt
	while read -r line; do
		sed 's/^[^(), :;]*//;s/[(), :;]/\n/g' <<< "$line" | sed '/./!d;s/^/ /' | sort -u > local_lines/tokens.txt
		requires="$(fgrep -f local_lines/tokens.txt local_lines/requires.txt)" || :
		printf "policy_module(%s_%d, 1.0.0)\nrequire {\n%s\n}\n%s\n" "${a%.te}" $cnt "$requires" "$line" > local_lines/"${a%.te}"_"$cnt".te
		(( cnt++ )) || :
	done < <(sed -n '/^policy_module(/d;/^[[:space:]]*require {/,/^[[:space:]]*}/d;/^[[:space:]]*#/d;/^$/d;/^tunable_policy/d;/^optional_policy/d;/^'"'"')/d;p' "$a")
done
