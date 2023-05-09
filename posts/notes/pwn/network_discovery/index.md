---
title: "Network Discovery"
---

<p style="text-align: right">_- last update 09/08/2022 -_</p>

## Presentation

This section explain how to discover the network topology, hosts and, eventually, bypass the NAC.

## NAC bypass

_TODO : find allowed mac and use macchanger_

## Scanning and host discovery

### DHCP informations

When entering a network, the DHCP is the first thing to look at. DHCP offers holds a lot of great informations on the local networks available:

* Look at the range delivered to you
* Look at the nameservers
* Look at other interesting fields (domain names for exemple)

_TODO : add script to show DHCP fields_

### DNS informations

A lot of platforms requires you to register DNS entries. Once you know some base DNS entries, you can enumerate them to find more hosts.

A great example is ActiveDirectory. The following nmap script can find all domain contrôlers using dns queries:

```bash
sudo nmap --script dns-srv-enum --script-args dns-srv-enum.domain=$DOMAIN_FQDN
```

For reference, the following oneliner is extracting and sorting the domain name of every domain contrôler.

```bash
sudo nmap --script dns-srv-enum --script-args dns-srv-enum.domain=$DOMAIN_FQDN | grep $DOMAIN_FQDN | sed 's/^.* //' | tr '[:upper:]' '[:lower:]' | sort -u | tee ads.txt
```

Use the following tools to extend DNS scope:

* [dnsrecon](https://github.com/darkoperator/dnsrecon)
* [amass](https://github.com/OWASP/Amass)
* [dnsdumpster](https://dnsdumpster.com/)
* [shodan](https://www.shodan.io/)

Use `whois` to get open source informations on all domains.

Use drill/dig to request names.


### List hosts and services

Fast and stealthy ARP and TCP scan on the network (does not scan ports).

```bash
sudo nmap -vv -oA ./nmap/scan0 -sn $NETWORK
```

Extract only up hosts.

```bash
cat ./nmap/scan0.gnmap | grep 'Status: Up' | cut -d ' ' -f 2 | tee ./nmap/hosts0
```

Some systems (windows) may not allow icmp, for this, do a -Pn scan anyway.

```bash
sudo nmap -vv -oA ./nmap/scan_1 -PN $NETWORK
```

_TODO: selection de port pour détecter uniquement les machines windows_

It's quite loud but `traceroute` is always a good idea to understand the network topology.

Once hosts are identified, you can make a full service scan.

```bash
sudo nmap -vv -oA ./nmap/scan_2 -sC -PN $NETWORK
```

_TODO: vérifier si cette commande fait des scan udp aussi_

URP scans are very slow (so you should restrict to 20 port max) but you should do them.

```bash
sudo nmap -vv -oA ./nmap/scan_3 -sU --top-ports 20 $TARGET
```

Use `--script` and `--script-help` to look for interesting NSE scripts to play.
You can search the database for that (`categorie = .*vuln`).

```bash
grep 'vuln' /usr/share/nmap/scripts/script.db \
| cut -d ' ' -f 5
```

* [List categories](https://nmap.org/book/nse-usage.html)
* [List scripts](https://nmap.org/nsedoc/)

On nix, find the `script.db` with:

```bash
ls -l $(which nmap) | rev | cut -d ' ' -f 1 | rev \
  | xargs dirname | xargs dirname \
  | xargs -I {} ls {}/share/nmap/scripts/script.db
```

Nmap provides a [firewall evasion](https://nmap.org/book/man-bypass-firewalls-ids.html) documentation.
