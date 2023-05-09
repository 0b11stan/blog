---
title: "SMB"
---

<p style="text-align: right">_- last update 10/08/2022 -_</p>

## Tools

[Crackmapexec](https://github.com/Porchetta-Industries/CrackMapExec) is a swiss army knife for pentesting networks. Installation (using podman) :

```bash
alias cme='mkdir -p ~/.cme && podman run -it --rm -v ~/.cme:/root/.cme -v $PWD:/srv -w /srv byt3bl33d3r/crackmapexec'
```

For a more simple approach, there is impacket's `smbclient.py` script.

## If you have user account

Using smbclient to connect and use `shares` to see interesting shares

```bash
smbclient.py guest@$TARGET
```

Test your authentication against the domain contrôler.

```bash
cme smb $DOMAIN_CONTROLER -d $DOMAIN_FQDN -u $USER -p "$PASSWORD"
```

### If you are in an active directory network

Get the password policy

```bash
cme smb $DOMAIN_CONTROLER -d $DOMAIN_FQDN -u $USER -p "$PASSWORD" --pass-pol
```

You can then proceed to spread passwords

```bash
cme smb $DOMAIN_CONTROLER -u users.txt -p users.txt --no-bruteforce
```

Some nice spreading to try:

* `user == password`: like exemple below
* default administration password (if you did find it)
* the city name (dict based on environment)
