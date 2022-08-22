---
title: "Network Discovery"
---

<p style="text-align: right">_- last update 09/08/2022 -_</p>

## Presentation

From here you have access to the network. You can send and recive packets between at least 2 hosts.

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
