---
title: "Service Discovery"
---

<p style="text-align: right">_- last update 09/08/2022 -_</p>

## Presentation

From here you have discovered some hosts on the network and want to know the service they provides.

This section explain how to scan for available services and gather informations about them.

## Scanning

_TODO : nmap basics_

## Discover Active Directory

Scan the network for port 88:

```bash
sudo nmap -oA krb_discovery -p 88 -Pn $TARGET
```

Find domain's FQDN by resolving netbios name in SMB headers :

```bash
grep 88/open krb_discovery.gnmap | cut -d ' ' -f 2 | xargs cme smb
```
