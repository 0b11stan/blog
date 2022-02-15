---
title: "Eth Piracy: Recon"
---

<p style="text-align: right">_- last update 14/12/2021 -_</p>

## Timeline

Découverte rapide des hôtes.

```bash
sudo nmap -vv -oA ./nmap/scan_0 -sn $NETWORK
```

Extraction des hôtes up.

```bash
cat /tmp/test1.gnmap | grep 'Status: Up' | cut -d ' ' -f 2 | tee /tmp/hosts
```

Découverte des hôtes windows.

```bash
sudo nmap -vv -oA ./nmap/scan_1 -Pn $NETWORK
```

Extraction des hôtes up.

```bash
cat /tmp/test1.gnmap | grep 'Status: Up' | cut -d ' ' -f 2 | tee -a /tmp/hosts
```

## Passive

Outils intéressants:

* [dnsrecon](https://github.com/darkoperator/dnsrecon)
* [amass](https://github.com/OWASP/Amass)
* [dnsdumpster](https://dnsdumpster.com/)
* [shodan](https://www.shodan.io/)

Classique: drill, whois, ...

## Active

* traceroute

## NMAP

A inclure dans (quasiment) toutes les commandes:

* l'option verbose `-vv`
* les export dans tout les formats `-oA 'path/basename'`
* toujours utiliser nmap en root pour activer toutes les features

Découverte des hôtes d'un réseau sans scan de port. (NMAP test la découverte par
le protocole ARP avant le ping mais pour ça il faut utiliser les privilèges
root.)

```bash
nmap -sn TARGET/CIDR
```

Si on veux découvrir du windows il faut utiliser l'option `-Pn` sans `-sn`
pour découvrir les hôtes parceque windows ne répond pas aux requêtes ICMP par
défaut.

Les scan UDP sont lent, il faut filtrer un max pour avoir des réponses rapides:

```bash
nmap -sU --top-ports 20 $TARGET
```

Il faut utiliser des scripts ! (option `--script` et `--script-help`).

Chercher dans les scripts disponibles depuis la base de donnée, on peut voir
quel script est dans quelle catégorie aussi (`categorie = .*vuln`).

```bash
grep '...' /usr/share/nmap/scripts/script.db \
| cut -d ' ' -f 5
```

* [Liste des catégories](https://nmap.org/book/nse-usage.html)
* [Liste des scripts](https://nmap.org/nsedoc/)

Pour aller vite, l'option `-sC` permet de jouer les scripts de la catégorie
`default`.

## A lire

* [firewall evasion](https://nmap.org/book/man-bypass-firewalls-ids.html)
