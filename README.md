<!--
SPDX-FileCopyrightText: 2021 Markus Linnala <markus.linnala@cybercom.com>

SPDX-License-Identifier: Apache-2.0
-->

# selinux\_user\_u
SELinux user\_u policy to fix Fedora 35+ issues

Install required packages:
```|sh
dnf install git make selinux-policy-devel policycoreutils-python-utils
```

## Targets

### login + logout works
reboot + login + logout + login + reboot
-> no AVC

There usually is some during:
- boot
- login
- logout
- reboot (kill)

### systemctl works

systemctl
-> no AVC

Each subsystem should survive start, stop, kill -9 (or similar) without AVC.

This kind of continues login/logout.

### fcontexts are set right automatically
```
restorecon -nvR /
```
-> no changes

Especially
```
restorecon -nvR /run
restorecon -nvRx /
```

There is regression with `/var/lib/mock/.../distribution-gpg-keys(/.*)?`
because python copies files wrongly.

### Contained user does not generate spurious AVC
```
find / -ls
ps -fe
```

### Try to achieve some contain
Use contained selinux users.

Minimize usage of `user_tmp_t`.

### Add: booleans

- `local_user_u_journalctl`: Allow to run `journalctl --user`

## Non targets

### user\_r admin programs

So no:
- su
- sudo
- consolehelper
-- mock
- containers
-- buildah
- selinux tools

Seems there is issue with podman container process transition I don't know how to fix.

It should be so that if you can not use certain commands, then you can not execute said commands, but that is not the case. For example `sudo` is not meant to be run, but `sudo_exec_t` is allowed via `application_executable_file`.
