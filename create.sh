#!/bin/sh

set -epux -o pipefail
make
sudo find  /etc/systemd/user /etc/xdg/systemd/user /run/systemd/user /run/user /usr/local/lib/systemd /usr/local/share/systemd /usr/share/systemd /var/lib/flatpak/exports/share/systemd /home/"$USER"/{\.config/systemd,\.local/share/systemd,\.local/share/flatpak/exports/share/systemd} -maxdepth 0 -type d -exec restorecon -vRF {} +
exit $?
