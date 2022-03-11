---
title: "Local File Inclusion"
---

<p style="text-align: right">_- last update 11/03/2022 -_</p>

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

OMG WAOUH on peut faire du RCE en utilisant [le bon filtre](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/File%20Inclusion#wrapper-data):

```txt
data://text/plain;base64,PD9waHAgc3lzdGVtKCdob3N0bmFtZScpOyA/Pg==
```

Le payload étant un base64 de `<?php system("hostname"); ?>`

