# PAM configuration for PIN authentication in GDM3 and SUDO

This project uses files from Debian, but the changes can be adapted to work with other distributions.

### Requirements

- openssl or mkpasswd for password generation
- libpam-script
- libpam-pwdfile

## Generate password file

Create the file with you PIN or short password:

`sudo sh -c 'echo -New Password:;echo '${USER}':`openssl passwd -6` > /etc/pinpwd; chmod 640 /etc/pinpwd'`

After this command the file /etc/pinpwd should have format 'user:password', something like this:

> user:$6$xxxxxxxxx

*The file should have mode 0640 and be owned by root:root.*

## Copy the pam config

Copy [pam/etc/pam.d/common-pinpwd](pam/etc/pam.d/common-pinpwd) to `/etc/pam.d/common-pinpwd`.

The file:

> /etc/pam.d/common-pinpwd

Should have the content:

```
auth    sufficient  pam_pwdfile.so  pwdfile=/etc/pinpwd
```

## Copy the pam script
Copy [scripts/pam/etc/pam.d/scripts/is-session-locked/pam_script_auth](scripts/pam/etc/pam.d/scripts/is-session-locked/pam_script_auth) to `/etc/pam.d/scripts/is-session-locked/pam_script_auth`.

## Changes

Edit the pam config files. You can see the diffs below, ***+ when the line is added, - when the line is removed***.

See [examples](examples) for the whole files, from Debian.

### SUDO

Sudo uses two pam config files, sudo and sudo-i. Below are the changes (in diff format):

The file:

> /etc/pam.d/sudo


Should be edited:

```
--- sudo.debiantrixie.orig	2025-01-18 16:21:43.903519337 -0300
+++ sudo	2025-01-18 17:57:03.003824770 -0300
@@ -3,6 +3,7 @@
 # Set up user limits from /etc/security/limits.conf.
 session    required   pam_limits.so

+@include common-pinpwd
 @include common-auth
 @include common-account
 @include common-session-noninteractive
```

<br/>

The file:

> /etc/pam.d/sudo-i

Should be edited:

```
--- sudo-i.debiantrixie.orig	2025-01-18 16:21:52.471519795 -0300
+++ sudo-i	2025-01-18 17:57:03.003824770 -0300
@@ -3,6 +3,7 @@
 # Set up user limits from /etc/security/limits.conf.
 session    required   pam_limits.so

+@include common-pinpwd
 @include common-auth
 @include common-account
 @include common-session
```

### GDM3

The parameter "[success=ignore default=1]" tells PAM to ignore the result of pam_script, it will be used just to jump the next line (default=1) from the included file, and go directly to common-auth if an error occurs (session not locked, login screen), or go to next line (pwdfile.so), if session is locked.

The file:

> /etc/pam.d/gdm-password

Should be edited:

```
--- gdm-password.debiantrixie.orig	2025-01-18 16:21:35.803518905 -0300
+++ gdm-password	2025-01-18 17:56:59.527824585 -0300
@@ -1,6 +1,8 @@
 #%PAM-1.0
 auth    requisite       pam_nologin.so
 auth	required	pam_succeed_if.so user != root quiet_success
+auth    [success=ignore default=1]  pam_script.so dir=/etc/pam.d/scripts/is-session-locked
+@include common-pinpwd
 @include common-auth
 auth    optional        pam_gnome_keyring.so
 @include common-account
```

### Optional: clear sudo credentials cache when lock screen

The script [scripts/home/bin/gdbus_monitor.sh](scripts/home/bin/gdbus_monitor.sh) clears the sudo cache when user locks the screen, it should start on login and keep running to monitor the lock screen event. Copy [scripts/home/bin/gdbus_monitor.sh](scripts/home/bin/gdbus_monitor.sh) to `~/bin/gdbus_monitor.sh`, and [scripts/home/.config/autostart/gdbus-monitor.desktop](scripts/home/.config/autostart/gdbus-monitor.desktop) to `~/.config/autostart/gdbus-monitor.desktop`.