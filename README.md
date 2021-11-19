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

As most AVC come when resources are created/started or deleted/stopped. Usually if you can create/delete a resource you can then use it, so it is quite rare to see AVC otherwise.

### systemctl works

systemctl
-> no AVC

Each subsystem should survive start, stop, kill -9 (or similar unplanned stop) without AVC.

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

Each subsystem should create all directories and files needed with right fcontext. So if subsystem creates/deletes filesystem resources, then you should test it with said resources not existing too. Even if during normal boot some other subsystem creates those resources.

### Contained user does not generate spurious AVC
System probing commands should not produce AVC:s.

For example:
```
find / -ls
ps -fe
systemctl status
```

If this is not implemented, then contained user can overload auditd by running those commands.

Add dontaudit rules or limit access to resources in other way.

### Try to achieve some contain
Use contained selinux users.

Limit uncontained daemons to 3rd party daemons not in distro control.
Currenty in F35 I see:
```
system_u:system_r:unconfined_service_t:s0 /usr/libexec/low-memory-monitor
system_u:system_r:unconfined_service_t:s0 /usr/libexec/switcheroo-control
system_u:system_r:unconfined_service_t:s0 /usr/sbin/thermald --systemd --dbus-enable --adaptive
system_u:system_r:unconfined_service_t:s0 /usr/libexec/uresourced
```
To implement contain for thermald should be easy. But anyways all of these should be contained.

Usage of `user_tmp_t` should be minimized to /run/user/<uid> dir and rest should have per subsystem domains with discrete subdirectory and then you can use randomized files if needed. This allows nice `filetrans_pattern`. Using random filenames means proper selinux context handling needs application selinux support.

Generally it is not good idea to put things in /tmp as there is also similar issue with contain and need to have randomized names.

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
