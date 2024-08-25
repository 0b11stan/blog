---
title: Defensive Nixos (3/3) - Outro
lang: fr
ref: defensive-nixos-3
---

## Resultat

```txt
> wc -l src/*.nix src/*.sh

  69 src/configuration.nix
  34 src/docker-nextcloud.nix
  42 src/hardware-configuration.nix
   2 src/init.sh
 147 total
```

NOTES:

* dérivation => 30aine de ligne
* 40aine de ligne généré automatiquement à l'installation du système
* pour la gestion des spécificités materiels, du bootloader et autre
* configuration globale ne dépasse pas les 70 lignes

## Nixos > All

- Versionnable <!-- .element: class="fragment" -->
- Automatisable <!-- .element: class="fragment" -->
- Reproductibilité / Idempotance <!-- .element: class="fragment" -->
- Liberté de configuration <!-- .element: class="fragment" -->
- Bare Metal & Env. Virtualisé <!-- .element: class="fragment" -->

NOTES:

* bref, en moins de 150 lignes de configuration
* écrite dans un language limpide,
* vous êtes en mesure de déployer
* un système de façon reproductible
* en allant jusqu'a définir un service systèmd spécifique pour votre application
* le tous déployable sur des machines virtuelles ou physiques

NOTES:

* que demander de plus me diriez vous ?
* le système offre beaucoup d'autres garanties

### Bonus - Isolation logicielle

```txt
$ echo $PATH | tr ':' '\n'

  /run/wrappers/bin
  /home/tristan/.nix-profile/bin
  /etc/profiles/per-user/tristan/bin
  /nix/var/nix/profiles/default/bin
  /run/current-system/sw/bin
```

NOTES:

* chaque logiciel n'à accès qu'a ses dépendances
* chaque environnement utilisateur est isolé des autres

### Bonus - Root en readonly

```txt
$ DERIVATION=$(ls -tp /nix/store/ | grep 'openssh.*/$')

$ ls -l /nix/store/$DERIVATION/etc/ssh/
total 504
-r--r--r-- 2 root root 505489  1 janv.  1970 moduli
-r--r--r-- 2 root root 1531  1 janv.  1970 ssh_config
-r--r--r-- 2 root root 3226  1 janv.  1970 sshd_config

$ sudo chmod +w /nix/store/$DERIVATION/etc/ssh/sshd_config
[sudo] Mot de passe de tristan :
chmod: modification des droits [...] Read-only file system
```

NOTES:

* FS root => readonly => en particulier le store
* attaquant => privesc => backdoor => openssh
  - emplacement openssh
  - file readonly
  - filesystem readonly
* seul moyen => réécrir un fichier nix 
  - doit correspondre au système
  - possible mais => augment complexité  attaques système
* facile à supperviser

### Bonus - Rollback

```txt
[tristan@demo:~]$ ls /boot/loader/entries/ | head -n 2
nixos-generation-131.conf  nixos-generation-132.conf

[tristan@demo:~]$ cat /boot/.../nixos-generation-131.conf
title NixOS
version Generation 131 NixOS 22.05.4120.16f4e04658c, Linux Kernel 5.15.78, Built on 2022-11-16
linux /efi/nixos/rax...xdm-linux-5.15.78-bzImage.efi
initrd /efi/nixos/846...sl3-initrd-linux-5.15.78-initrd.efi
options init=/nix/store/4jx...17f-nixos-system-demo-22.05.4120.16f4e04658c/init loglevel=4
machine-id b7bfdd5f273b49c6a30c4e26e84c8f21
```

NOTES:

* nixos => les erreurs coutent moins cher
* reboot => bootloader proposera entrée => précédents état de la configuration
* exemple: entrée de boot => point vers dérivation

### Les inconvenients

- Moins "Flexible" <!-- .element: class="fragment" -->
- Croissances du Nix store <!-- .element: class="fragment" -->
- Systemd centric <!-- .element: class="fragment" -->
- Adoption = changement d'OS <!-- .element: class="fragment" -->
- Surcharge de Nixpkgs <!-- .element: class="fragment" -->

NOTES:

* flexibilité => /etc/hosts => prix à payer pour garantie d'intégrité serveurs

* possibilités:
  - d'installer des version concurrente de plusieurs librairies
  - d'avoir des environnements isolés 
  - et de pouvoir rollback quand ont veux
* nécessite => code en doublons dans le nix store
* garbage collector très efficace => supprimer les D des N dernières générations

CLICK

vous l'avez peut-être vue tout à l'heure sur ma capture d'écran du dépôt github

de nixos mais il y à un peu d'embouteillage dans les issues

cette semaine je comptais :

* plus de 5000 issues
* et plus de 4000 pull request en attente

si c'est une preuve de la popularité croissante du projet

ça dénote aussi d'un manque de correlation entre la facilité à écrire des
dérivations et les moyens humains qui peuvent être déployés pour faire la revue
des codes

si le projet vous intéresse, c'est ici qu'on à besoin de vous

CLICK

si systemd vous donne des allergies, nixos n'est pas pour vous, comme on l'a vu
au dessus il s'appuie grandement sur ce système d'init pour avoir un controle
très fin sur les services qui sont executés

il existe bien des
projet de distribution équivalentes sans systèmd mais ils sont au stade
pré-embryonnaires


CLICK

Enfin, une dernière chose que l'on pourrait critiquer à propos de nixos c'est
sont manque d'adaptabilité aux environnements techniques en place, la ou ansible
peut être utilisé
du jour au lendemin pour déployer de l'infrastructure en s'adaptant à n'importe
quel distribution, nixos nécessite de nouvelles installation

cependant, si je me suis concentré sur nixos parceque je pense que c'est vraiment
la ou le projet dépoie tous son potentiel, n'oubliez pas que nix
est avant tout un gestionaire de packet et que celui-ci peut être installé sur
n'importe quel distribution linux

vous pouvez déjà commencer à utiliser vos premières dérivations nix en prod
avant même de passer sur nixos

CLICK


fin des conflits

_voir les questions_

### Conclusion

<div class="column">
  <img src="/assets/drafts/slideshow.png">
  <p class="subtitle">https://github.com/0b11stan/hackitn-nixos-slideshow</p>
</div>
<div class="column">
  <img src="/assets/drafts/demo.png" >
  <p class="subtitle">https://github.com/0b11stan/hackitn-nixos-demo</p>
</div>

NOTES:

Très bonne doc et plein de projets subsidiaires : home-manager, flakes, hydra, nixops, ...

encourage à tester

Passez au stand capgemini pour questions

---
<!-- .slide: data-background="#ffffff" -->

![](/assets/drafts/hackitnix.png)

### sources

https://nixos.org/community/teams/security/
https://nixos.org/guides/nix-pills/
https://nixos.org/
https://nixos.wiki/wiki/Security
https://nix.dev/manual/nix/2.18/#ch-nix-security
