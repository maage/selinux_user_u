#!/bin/sh

rm -rf export
mkdir -p export
pushd export
args=() # --verbose)
for a in $(sudo semodule -l); do
	args+=(--cil --extract="$a")
done

sudo semodule "${args[@]}"

popd
chown -R "$SUDO_USER": export
