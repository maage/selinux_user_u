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

make -f /usr/share/selinux/devel/Makefile local_user_u.pp
sudo /usr/sbin/semodule -i local_user_u.pp
sudo find  /etc/systemd/user /etc/xdg/systemd/user /run/systemd/user /run/user /usr/local/lib/systemd /usr/local/share/systemd /usr/share/systemd /var/lib/flatpak/exports/share/systemd /home/"$USER"/{\.config/systemd,\.local/share/systemd,\.local/share/flatpak/exports/share/systemd} -maxdepth 0 -type d -exec restorecon -vRF {} +
exit $?
