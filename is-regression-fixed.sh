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
if [ "$src" ]; then
	src_rx="$(rx_escape "$src")"
	get_typeattributeset src_attrs "$src_rx"
fi

tgt_attrs=()
if [ "$tgt" ]; then
	tgt_rx="$(rx_escape "$tgt")"
	get_typeattributeset tgt_attrs "$tgt_rx"
fi

rx="[(]$(rx_escape "$typ") ("

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

perm_helper() {
	sed -r '
/(.).*\1/d;
s/A/0,/;
s/B/1,/;
s/C/2,/;
s/D/3,/;
s/E/4,/;
s/F/5,/;
s/,$//;
'
}

if (( ${#perms[@]} )); then
	if (( ${#perms[@]} == 1 )); then
		ax=(A)
	elif (( ${#perms[@]} == 2 )); then
		ax=({A,B}{A,B})
	elif (( ${#perms[@]} == 3 )); then
		ax=({A,B,C}{A,B,C}{A,B,C})
	elif (( ${#perms[@]} == 4 )); then
		ax=({A,B,C,D}{A,B,C,D}{A,B,C,D}{A,B,C,D})
	elif (( ${#perms[@]} == 5 )); then
		ax=({A,B,C,D,E}{A,B,C,D,E}{A,B,C,D,E}{A,B,C,D,E}{A,B,C,D,E})
	elif (( ${#perms[@]} == 6 )); then
		ax=({A,B,C,D,E,F}{A,B,C,D,E,F}{A,B,C,D,E,F}{A,B,C,D,E,F}{A,B,C,D,E,F}{A,B,C,D,E,F})
	else
		echo "ERROR: too many to permute, implement it"
		exit 1
	fi

	rx+="[(]("
	while read -r permutation; do
		IFS=, read -r -a idx_arr <<< "$permutation"
		rx+="([^()]* )?"
		flag=0
		for idx in "${idx_arr[@]}"; do
			if (( flag )); then
				rx+="( [^()]*)? "
			else
				flag=1
			fi
			rx+="$(rx_escape "${perms[$idx]}")"
		done
		rx+="( [^()]*)?"
		rx+="|"
	done < <(
		for a in "${ax[@]}"; do 
			printf "%s\n" "$a"
		done | perm_helper
	)

	rx="${rx%|})[)]"
else
	rx+="[(][^)]*[)]"
fi

set -x
grep -Er "$rx" export
