#!/bin/bash
set -eEpux -o pipefail

declare -i s0 s1 s2 s3 s4 s5
s1="$1"; shift
s4="$1"; shift
(( s0=s1-1, s2=s1+1, s3=s4-1, s5=s4+1 )) || :

sed -Eni "${s1}{x;d};1,${s0}{p};${s2},${s4}{p};${s4}{x;p};${s5}"',${p}' "$@"
