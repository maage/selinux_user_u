#!/bin/bash

set -epu -o pipefail

src=
tgt=
cls=
perm=
perms=()
typ="allow"

while (( $# )); do
	case "$1" in
		--allow|--auditallow|--dontaudit|--neverallow|--allowxperm|--auditallowxperm|--dontauditxperm|--neverallowxperm) typ="${1#--}"; shift ;;
		--attr) typ="typeattributeset"; shift ;;
		-s|--source) (( $# >= 2 )) || exit 1; src="$2"; shift 2 ;;
		-t|--target) (( $# >= 2 )) || exit 1; tgt="$2"; shift 2 ;;
		-c|--class) (( $# >= 2 )) || exit 1; cls="$2"; shift 2 ;;
		-p|--perm) (( $# >= 2 )) || exit 1; perm="$2"; shift 2 ;;
	esac
done

if [ "$perm" ]; then
	IFS=, read -r -a perms <<< "$perm"
fi

#
#
#

rx_escape() {
	sed 's/[^^a-zA-Z0-9_]/[&]/g; s/\^/\\^/g' <<< "$1"
}

get_typeattributeset() {
	declare -n attrs="$1"; shift
	local rx="$1"; shift
	while read -r tas attr rest; do
		if [ "$tas" != "(typeattributeset" ]; then
			echo "ERROR: Parse error: $tas $attr $rest"
			exit 1
		fi
		attrs+=("$attr")
	done < <(grep -Erh '[(]typeattributeset ' export | sed '/ cil_gen_require /d;/[( ]'"$rx"'[) ]/!d;s/^[[:space:]]*//')
}

src_attrs=()
tgt_attrs=()
if [ "$typ" = "typeattributeset" ]; then

	rx="/[(]$(rx_escape "$typ") /!d;"
	rx+="/[(]$(rx_escape "$typ") cil_gen_require /d;"

	if [ "$src" ]; then
		rx+="/[(]$(rx_escape "$typ") $(rx_escape "$src") /!d;"
	fi

	if [ "$tgt" ]; then
		rx+="/[( ]$(rx_escape "$tgt")[) ]/!d;"
	fi

	grep -r ^ export | sed -r "$rx"
	exit 0
fi

if [ "$src" ]; then
	src_rx="$(rx_escape "$src")"
	get_typeattributeset src_attrs "$src_rx"
fi

if [ "$tgt" ]; then
	tgt_rx="$(rx_escape "$tgt")"
	get_typeattributeset tgt_attrs "$tgt_rx"
fi

rx="/[(]$(rx_escape "$typ") ("

if [ "$src" ]; then
	for a in "$src" "${src_attrs[@]}"; do
		rx+="${a}|"
	done
else
	rx+="[^ ]*|"
fi

rx="${rx%|}) ("

if [ "$tgt" ]; then
	for a in "$tgt" "${tgt_attrs[@]}"; do
		rx+="${a}|"
	done
else
	rx+="[^ ]*|"
fi

rx="${rx%|}) [(]"

if [ "$cls" ]; then
	rx+="$(rx_escape "$cls") "
else
	rx+="[^ ]* "
fi

if (( ${#perms[@]} )); then
	# This makes multiple prefix matches, much simpler than permutations
	frx="$rx[(]"
	rx+="/!d;"
	for a in "${perms[@]}"; do
		rx+="$frx([^()]* )?$(rx_escape "$a")[ )]/!d;"
	done
else
	rx+="[(][^)]*[)]/!d;"
fi

set -x
exec grep -r ^ export | sed -r "$rx"
