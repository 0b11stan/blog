---
title: "Web Application Exploitation"
---

<p style="text-align: right">_- last update 22/11/2021 -_</p>

Avant de commencer, le [web security testing guide](https://owasp.org/www-project-web-security-testing-guide/stable/)
est un excellent document pour réaliser un test d'intrusion web.


### Scanners de vulnérabilités

L'outil [nessus](https://www.tenable.com/products/nessus) est un scanner très
célèbre et qui permet d'obtenir une vision très graphique du scan. Cela peut
être un bon point de départ pour identifier les vulnérabilités les plus
évidentes.

### Scan SSL

Il y à l'outil `sslscan` qui est génial

Quand on à une grande liste de sites, on peut scanner facilement le cette façon

```bash
for host in $(cat apps.txt); do echo ">>> $host"; echo '' | timeout 2 openssl s_client -port 443 -connect $host 2>/dev/null | grep -i verification; done | tee openssl.txt
```

Ensuite on peut filtrer les éléments intéressant:
```bash
> cat openssl.txt | grep -v 'Verification: OK' | grep -B1 Verification
```

Ca va sortir un truc comme ça

```
>>> testa.sample.fr
Verification error: self signed certificate in certificate chain
--
>>> testb.sample.fr
Verification error: unable to verify the first certificate
--
>>> testc.sample.fr
Verification error: certificate has expired
--
>>> testd.sample.fr
Verification error: unable to verify the first certificate
--
>>> teste.sample.fr
Verification error: certificate has expired
```

## Reverse Connection

Tools:

* [request.bin](https://requestbin.com/)
* [ngrok](https://ngrok.com/)

Methode pour copier le fonctionnement en local.

Dans un premier temps il faut simplement décommenter l'option `GatewayPorts` et
la mettre à true dans le fichier de configuration ssh du serveur publique:

```bash
# cat /etc/ssh/sshd_config | grep Gateway
GatewayPorts yes
```

Ensuite, pour exporter un port local sur internet:

```bash
ssh -NR 4444:localhost:8000 tristan@tic.sh &
```

Le port `8000` local sera exposé sur le port `4444` de `tic.sh` et les requettes
seront toutes forwardé. L'option `-N` évite d'ouvrir un shell et le `&` à la fin
de la ligne permet de jouer cette commande en background et donc de
redonner la main au shell.

## Reconnaissance

[reconnaissance][./recon.md)

## IDOR

[idor](./idor.md)

## LFI

[lfi](./lfi.md)

## Bypass WAF

Ajouter un header [X-Forwarded-For](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-For)
peut override celui du WAF et donc bypass la protection.

## Injections

Il existes un grand nombre de techniques pour l'injection de code dans une
application, elles sont propre au language utilisé:

* [php](./php)
* [sql](./sql)
* [nosql](./nosql)
* [javascript](./javascript)

## Reverse shell

[The pentestmonkey repo](https://github.com/pentestmonkey/php-reverse-shell/blob/master/php-reverse-shell.php)
contain a nice reverse proxy for php.

The variables `$ip` and `$port` must be changed, pointing to a listening netcat
connection. [Here](https://raw.githubusercontent.com/pentestmonkey/php-reverse-shell/master/php-reverse-shell.php) 
is a direct download.

On peut trouver également des payload dans [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)
et [SecLists](https://github.com/danielmiessler/SecLists/tree/master/Web-Shells).

## Breaking flash applications

[ruffle](http://ruffle.rs/#) est un émulateur pour flash écrit en rust. A
l'heure ou j'écris (17/11/2021), il ne supporte que ActionScript 1 et 2 mais
cela ne [devrais pas tarder](https://github.com/ruffle-rs/ruffle/wiki/Frequently-Asked-Questions-For-Users) 
pour la version 3. S'utilise comme un plugin du navigateur.

En attendant, il y à [lightspark](https://lightspark.github.io/).

## Working with cookies

Une bonne façons de réinjecter du token CSRF avec les fichiers de cookie au 
format Netscape.

```bash
curl -X PATCH 'https://target.tld/api/path' \
  -H "X-XSRF-TOKEN: $(cat cookies.txt | grep XSRF | cut -d $'\t' -f 7)" \
  -b cookies.txt \
  -H 'content-type: application/json' 
  -d '{"enabled":false}'
```

Le plugin [ExportCookies](https://github.com/rotemdan/ExportCookies) sur firefox
permet d'extraire les cookies du site une fois authentifié. Il y à aussi
l'option `--cookie-jar` de curl.

