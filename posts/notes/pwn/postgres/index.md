---
title: "PostgreSQL"
---

<p style="text-align: right">_- last update 17/12/2022 -_</p>

## Using Metasploit

Dump the schema

```
msf> use auxiliary/scanner/postgres/postgres_schemadump
msf> run postgres://USERNAME:PASSWORD@TARGET_IP/postgres
```

Run commands

```
msf> use auxiliary/admin/postgres/postgres_sql
msf> run postgres://USERNAME:PASSWORD@TARGET_IP/postgres sql='MY SQL COMMAND'
```
