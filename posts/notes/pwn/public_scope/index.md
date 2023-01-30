---
title: "Public Scope Discovery"
---

<p style="text-align: right">_- last update 30/01/2022 -_</p>

## Extract subdomains

Using [amass](https://github.com/OWASP/Amass)

```bash
amass intel -v -o amass-intel-$DOMAIN.txt -exclude networksdb -whois -d $DOMAIN
amass enum -v -o amass-enum-$DOMAIN.txt -brute -min-for-recursive 2 -d $DOMAIN
```

Using [dnsrecon](https://github.com/darkoperator/dnsrecon)

```bash
dnsrecon -v -t bing -c dnsrecon-bing-$DOMAIN.csv -d $DOMAIN
dnsrecon -v -t yand -c dnsrecon-yand-$DOMAIN.csv -d $DOMAIN
dnsrecon -v -t crt -c dnsrecon-crt-$DOMAIN.csv -d $DOMAIN
```

Then try [dnsdumpster](https://dnsdumpster.com/)

## Aggregate

Add, uniq and sort all domains

```bash
cat *.txt | rev | sort -u | rev | tee hosts.txt
```

Resolv hosts

```bash
for host in $(cat hosts.txt); do printf "$host;$(dig +short $host | grep -v [a-z] | tr $'\n' ';' | head -c -1)\n"; done | tee resolved.csv
```
```bash
for host in $(cat hosts.txt); do
  addresses=$( \
    dig +short $host \
    | grep -v [a-z] \
    | tr $'\n' ';' \
    | head -c -1 \
  )
  printf "$host;$addresses\n"
done | tee resolved.csv
```

Get IP targets from resolved

```bash
cat resolved.csv | cut -d ';' -f 2- | tr ';' $'\n' | sort -u | tee addresses.txt
```

## Spider

Use burp's passive scan or other spider tools to find new domains in web pages and aggregate.
