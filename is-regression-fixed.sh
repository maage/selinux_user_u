#!/bin/bash

set -epux -o pipefail

src="$1"
tgt="$2"
shift 2

rx_escape() {
	sed 's/[^^a-zA-Z0-9_]/[&]/g; s/\^/\\^/g' <<< "$1"
}

src_rx+="$(rx_escape "$src")"
tgt_rx+="$(rx_escape "$tgt")"

get_typeattributeset() {
	declare -n attrs="$1"; shift
	local rx="$1"; shift
	while read -r tas attr rest; do
		if [ "$tas" != "(typeattributeset" ]; then
			echo "ERROR: Parse error: $tas $attr $rest"
			exit 1
		fi
		attrs+=("$attr")
	done < <(grep -Erh '[(]typeattributeset '|sed '/ cil_gen_require /d;/[( ]'"$rx"'[) ]/!d;s/^[[:space:]]*//')
}

src_attrs=()
get_typeattributeset src_attrs "$src_rx"
tgt_attrs=()
get_typeattributeset tgt_attrs "$tgt_rx"

rx="[(]allow ("
for a in "$src" "${src_attrs[@]}"; do
	rx+="${a}|"
done
rx="${rx%|}) ("
for a in "$tgt" "${tgt_attrs[@]}"; do
	rx+="${a}|"
done
rx="${rx%|}) .*[( ]("
for a in "$@"; do
	rx+="$(rx_escape "$a")|"
done
rx="${rx%|})[( ]"
grep -Er "$rx"
