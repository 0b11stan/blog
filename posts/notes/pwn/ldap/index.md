---
title: "LDAP"
---

<p style="text-align: right">_- last update 09/08/2022 -_</p>

## Tools

[BloodhoundAD](https://github.com/BloodHoundAD/BloodHound) is an LDAP forest analyser.

[Bloodhound.py](https://github.com/fox-it/BloodHound.py) is an ingestor for the [BloodhoundAD](https://github.com/BloodHoundAD/BloodHound) tool.

## If you have user account

You can dump the forest using bloodhound

On peut extraire des infos de la fôret

```bash
bloodhound-python --zip -c All -d $DOMAIN_FQDN -u $USER -p "$PASSWORD" -dc $DOMAIN_CONTROLER --disable-pooling -w 1
```

Filtrer les infos intéressantes de tous les utilisateurs

```bash
jq '.data | .[].Properties | {name: .name, display: .displayname, title: .title, desc: .description}' users.json | tee filtered_users.json
```

Chercher un utilisateur à partir de son ID

```bash
jq '.data | .[].Properties | select(.name == "<user-id>@<domain-fqdn>")' users.json
```

Extraire tous les nom d'utilisateur

```bash
jq '.data | .[].Properties.name' input.json | tee output.json
```
