---
title: "LDAP"
---

<p style="text-align: right">_- last update 17/08/2022 -_</p>

## Tools

* [BloodhoundAD](https://github.com/BloodHoundAD/BloodHound) is an LDAP forest analyser.
* [Bloodhound.py](https://github.com/fox-it/BloodHound.py) is an ingestor for the [BloodhoundAD](https://github.com/BloodHoundAD/BloodHound) tool.
* [Windapsearch](https://github.com/ropnop/go-windapsearch) is an easy ldap client for querying ldap service.

## If you do not have a user account

The following command extracts interesting informations on your AD.
The most useful is probably the "domainFunctionnality", which is showing the compatibility level of your domain with old (and therefor vulnerable) microsoft versions and protocoles.

```bash
windapsearch -d $DOMAIN_FQDN -m metadata
```

For exemple the following oneliner is extracting the functionality level for each DC.

```bash
for host in $(cat ads.txt); do 
  printf "$host "
  timeout 3 windapsearch -d "$DOMAIN_FQDN" --dc "$host" -m metadata \
    | grep -e 'domainControllerFunctionality'
  echo; sleep 3
done | tee funclevel.txt
```

## If you have user account

### Dumping the forest

You can dump the forest using either [SharpHound](https://github.com/BloodHoundAD/SharpHound) or [Bloodhound python](https://github.com/fox-it/BloodHound.py).

The following script put the `bloodhound-python` command in your current path :

```bash
#!/bin/sh

DOCKERFILE=$(mktemp)

cat > $DOCKERFILE <<EOF
FROM python:3
RUN pip install bloodhound
CMD bloodhound-python
EOF

podman build -t bloodhound-python -f $DOCKERFILE

alias bloodhound-python='podman run bloodhound-python'
```

The following command extract the forest.

```bash
bloodhound-python --zip -c All -d $DOMAIN_FQDN -u $USER -p "$PASSWORD" -dc $DOMAIN_CONTROLER --disable-pooling -w 1
```

### Extracting usefull informations from the dump

Once you have the data, you can freely query the LDAP database offline. Here are
some examples.

Generate a json with only the juicy informations about each users.

```bash
jq '.data | .[].Properties | {name: .name, display: .displayname, title: .title, desc: .description}' users.json | tee filtered_users.json
```

Look for a user using it's ID.

```bash
jq '.data | .[].Properties | select(.name == "<user-id>@<domain-fqdn>")' users.json
```

Extract every username.

```bash
jq -r '.data | .[].Properties.name' input.json | tee all_users.json
```

### Analysing the forest using bloodhound

Upload your `*.json` files to bloodhound for him to build a graph. You can then
search for specific targets or use the pre-defined queries.

Look for the query called "shortest path to admin" and export the graph.

_TODO : screenshot_

Extract every ldap objects from the graph into a `graph_objects.txt`.

```bash
sed -n 's/^[ ]*"\(.*\)@SAMPLE.DOMAIN.LOCAL.*/\1/p' graph.json | sort -u | tee graph_objects.txt
```

At this point the `graph_objects.txt` contains users, laptops and groups. You
can use the following python script to cross reference object that are only
users (using the extracted informations from previous section).

This python script takes a `graph_objects.txt` and a `all_users.txt` and stores
only real users inside `graph_users.txt`.

```python
valid_users = []

with open('all_users.txt', 'r') as f_all_users:
  all_users = f_all_users.read().split('\n')

with open('graph_objects.txt', 'r') as f_graph_users:
  graph_object = f_graph_object.read().split('\n')

for obj in graph_object:
  if obj in all_users:
    print(f'{obj} is a valid user')
    valid_users.append(obj)

with open('graph_users.txt', 'w') as f_graph_users:
  f_graph_users.write('\n'.join(valid_users))
```

You can then focus your attacks ([spraying](../smb) or phishing for example) on these users only.

## Tracking changes in the forest

Use [LDAPmonitor](https://github.com/p0dalirius/LDAPmonitor).

You can detect locked accounts, privilege escalations and see best activity peak
to launch poisonning.

## Read LAPS computer's password

Use [pyLAPS](https://github.com/p0dalirius/pyLAPS).

LAPS = Local Administrator Password Solution.

