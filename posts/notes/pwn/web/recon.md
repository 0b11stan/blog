---
title: "Web Reconnaissance"
---

<p style="text-align: right">_- last update 11/03/2022 -_</p>

## Découverte de sous-domaines

### Brute force

On peut utiliser l'outil [dnsrecon](https://github.com/darkoperator/dnsrecon)
pour cela. Dans la commande suivante on bruteforce `btr` les sous domaines en
utilisant le dictionnaire par défaut de l'outil.

```bash
dnsrecon -t brt -d target.tld
```

### OSINT

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

### Virtual Hosts

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

## Découverte d'endpoint racine

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

## Découverte de contenu

Il est important d'avoir une bonne vision de la surface d'attaque. Pour cela on
peut utiliser des méthodes passives ou actives.

### Passives

#### Contenu

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


#### Versions

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

#### Données techniques

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

## Dorking 

[dorking](./dorking.md)

