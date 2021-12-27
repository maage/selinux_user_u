#!/bin/sh

set -epu -o pipefail

grs='[[:space:]]*gen_require\(`[[:space:]]*'
ops='[[:space:]]*optional_policy\(`[[:space:]]*'
me='[[:space:]]*'"'"'\)[[:space:]]*'
con='[[:space:]]*(attribute|attribute_role|bool|class|role|user|type) [^\n]+[[:space:]]*'

sed_reorder() {
    local -n ref_cmds="$1"; shift
    local -i lmin="$1"; shift

    local -i s0 s1 s2 s3 s4 s5
    s1="$1"; shift
    s4="$1"; shift

    (( s0=s1-1, s2=s1+1, s3=s4-1, s5=s4+1, 1 ))
    ref_cmds+=("${s1}{x;d};${lmin},${s0}{p};${s2},${s4}{p};${s4}{x;p};")
}

myselint=(
    selint -r --context=../selinux-policy --disable={S-001,S-002,W-010,W-011}
)

out_of_orders=(
    ' Line out of order.  It is of type general interface after line '
    ' Line out of order.  It is of type general interface before line '
    ' Line out of order.  It is of type kernel module interface after line '
    ' Line out of order.  It is of type kernel module interface before line '
    ' Line out of order.  It is of type optional policy block after line '
    ' Line out of order.  It is of type optional policy block before line '
    ' Line out of order.  It is of type own module rule after line '
    ' Line out of order.  It is of type own module rule before line '
    ' Line out of order.  It is of type self rule after line '
    ' Line out of order.  It is of type self rule before line '
    ' Line out of order.  It is of type tunable policy block after line '
    ' Line out of order.  It is of type tunable policy block before line '
)

is_okay() {
    local f="$1"; shift
    local -i rc=0
    { "${myselint[@]}" "$f" || : ; } | grep -Eq ': \([EF]\): ' || rc=$?
    if (( rc == 0 )); then
        "${myselint[@]}" "$f"
        exit  1
    fi
}

if (( $# )); then
    paths=("$@")
else
    paths=(.)
fi

declare -A known_keys=(
    [W-001]=3
    [W-005]=2
    [C-001]=1
    [C-006]=4
)

declare -A files=()

update_files() {
    local f l1 tt line
    while IFS=: read -r f l1 tt line; do
        local key
        if [ "$line" ] && [[ "$line" =~ \([CSW]-[0-9][0-9][0-9]\) ]]; then
            key="${line##*(}"
            key="${key%%)*}"
        fi
        [ "$key" ] || continue
        [ "${known_keys[$key]:-}" ] || continue

        files["$f"]=1
    done < <("${myselint[@]}" "$@")
    wait $!
}

update_files "${paths[@]}"

for f in "${!files[@]}"; do
    is_okay "$f"

    declare -i advanced=1 keys_tract=1 had_keys=0
    while (( advanced-- > 0 )); do
        for key in "${!known_keys[@]}"; do
            cmds=()
            (( ${known_keys[$key]} == keys_tract )) || continue
            had_keys=1

            lines=()
            declare -i lmax=0 l1=0
            while IFS=: read -r ff l1 tt line; do
                # check possible parse errors
                [ "$f" == "$ff" ]
                [ "$line" ]
                lines+=("${l1}:${line}")
            done < <(selint -r --context=../selinux-policy --only-enabled --enable="$key" "$f")
            wait $!

            for line in "${lines[@]}"; do
                IFS=: read -r l1 line <<< "$line"
                # stability: only one linespan at a time
                (( l1 > lmax )) || continue
                printf "%s: %s: %s: %s\n" "$f" "$key" "$l1" "$line"
                case "$key" in
                    W-001)
                        [[ "$line" =~ ^' No explicit declaration for '[^\ ]+' from module '[^\ ]+'.  You should access it via interface call or use a require block. (W-001)'$ ]]
                        typ="${line# No explicit declaration for }"
                        typ="${typ%% *}"
                        tt="attribute"
                        case "$typ" in
                            *_r) tt="role" ;;
                            *_t) tt="type" ;;
                            *_u) tt="user" ;;
                        esac
                        cmds+=("$(printf '%d{i\\\ngen_require(`\\\n\t%s %s;\\\n'"'"')\n};' "$l1" "$tt" "$typ")")
                        (( lmax=l1, 1 ))
                        break
                        ;;
                    W-005)
                        [[ "$line" =~ ' Call to interface '[^\ ]+' defined in module '[^\ ]+' should be in optional_policy block ' ]]
                        cmds+=("$(printf '%d{i\\\noptional_policy(`\na\\\n%s)\n};' "$l1" "'")")
                        (( lmax=l1, 1 ))
                        ;;
                    C-006)
                        [[ "$line" =~ ^' Unordered declaration in require block ' ]]
                        line="${line# Unordered declaration in require block (}"
                        before="${line%% before *}"
                        after="${line##* before }"
                        after="${after%%)*}"
                        # Linenumber is the start of require block, so this is not so easy
                        # Iterate over require block starting the line, collect lines to pattern space
                        # Swap entries in wrong order if already there
                        # Keep iterating until swap done
                        cmds+=('
:a;
s/[[:blank:]]+$//;
'"${l1},/${me}/"'{
    N;
    s/(\b'"${before%% *}[[:blank:]]+${before##* }"'\b)(.*)(\b'"${after%% *}[[:blank:]]+${after##* }"'\b)/\3\2\1/;
    T a;
};
')
                        (( lmax=l1, 1 ))
                        break
                        ;;
                    C-001)
                        # Go over possible matches line by line
                        for m in "${out_of_orders[@]}"; do
                            if [[ "$line" =~ "$m" ]]; then
                                s2="${line#$m}"
                                s2="${s2%% *}"
                                declare -i l2="$s2"
                                if (( l2 )); then
                                    # after or before
                                    if (( l1 > l2 )); then
                                        declare -i lt
                                        (( lt=l1, l1=l2, l2=lt, 1 ))
                                    fi
                                    # stability: only one linespan at a time
                                    (( l1 > lmax )) || break
                                    sed_reorder cmds "$((lmax+1))" "$l1" "$l2"
                                    (( lmax=l2, 1 ))
                                fi
                                break
                            fi
                        done
                    ;;
                    *) exit 1;
                esac
            done

            if (( ${#cmds[@]} )); then
                sums=()
                sums+=("$(sha256sum -- "$f")")
                # selint -r --context=../selinux-policy --only-enabled --enable="$key" "$f" > r-orig
                case "$key" in
                    W-001)
                        sed -Ei "${cmds[*]}" "$f"
                        # Iterate from start of gen_require
                        # Remove consecutive end, start
                        # Iterate while content is matching
                        sed -Ei '
:a;
s/[[:blank:]]+$//;
/^'"$grs"'($|\n)/{
    N;
    s/(^|\n)'"$me"'\n'"$grs"'//;
    /(^|\n)('"${con}|${grs}|${me}"')?$/{ b a; };
}
' "$f"
                        ;;
                    W-005)
                        sed -Ei "${cmds[*]}" "$f"
                        ;;
                    C-001)
                        sed -Eni "${cmds[*]}$((lmax+1))"',${p};' "$f"
                        # Iterate from start of optional
                        # Remove empty
                        # Iterate while content is matching
                        sed -Ei '
:a;
s/[[:blank:]]+$//;
/^'"$ops"'($|\n)/{
    N;
    s/(^|\n)'"$ops"'\n'"$me"'//;
    /(^|\n)('"${ops}|${me}"')?$/{ b a; };
}
' "$f"
                    ;;
                    C-006)
                        sed -Ei "${cmds[*]}" "$f"
                        ;;
                    *) exit 1 ;;
                esac
                sums+=("$(sha256sum -- "$f")")
                # selint -r --context=../selinux-policy --only-enabled --enable="$key" "$f" > r-curr
                if [ "${sums[0]}" == "${sums[1]}" ]; then
                    printf "ERROR(%s): No change '%s' '%s'\n" "$f" "$key" "${cmds[*]}"
                    exit 1
                fi
                is_okay "$f"
                advanced=1
            fi
        done
        if (( (advanced <= 0) && had_keys )); then
            (( keys_tract++ ))
            advanced=1
            had_keys=0
        fi
    done
done
