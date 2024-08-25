---
title: Defensive Nixos
lang: fr
ref: defensive-nixos
---

Il me semble qu'elle fait encore partie des distribution linux qu'on peut qualifier de "niche".
Pourtant, NixOS (et les quelques projets plus modestes qui ont suivi la même philosophie) fait de plus en plus parler de lui.
Il est possible, si vous trainer vos guettres dans les communautés de mainteneurs, de libristes ou que votre travaille tourne autour de la SRE et du DevOps, que vous ayez vu passer au coin d'un article, d'un commentaire ou même d'une discution avec un collègues un peu farfellu, le nom de cette distribution.

NixOS est maintenant mon outil de travail principal depuis 3 ans.
Malgrès son jeune age, ses avantages en terme de robustesse, de maintenabilité et de sécurtié sont, à mon avis, inégalés.
Tous les organismes qui en ont la maturité gagnerais à dépoyer à grande échelle ce type de systèmes.
C'est donc la raison pour laquelle je démarre une petite série d'articles sur le sujet.
Même sans parler d'un changement complet de système, il me semble que ses mechanismes sont une très belle source d'inspiration pour ceux qui travaillent dans le dévellopement et la maintenance d'infrastructures.

Les premiers articles se contenterons de revenir ce que j'ai déjà présenté dans ma conférence sur le sujet à la Hack'it'N de 2022.

<iframe width="740" height=420 src="https://www.youtube.com/embed/GpJdcgxwxVE?start=23867" title="Live Hack It N" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

<br>

Biensure, expliquer le fonctionnement détaillé de NixOS dans une poignée d'articles n'est pas envisageable, d'autant qu'il existe déjà les excellents [nix pills](https://nixos.org/guides/nix-pills/).
Ces articles écrits par un des principaux contributeurs de la communauté NixOS sont d'une rare qualitée et constituent la porte d'entrée privilégiée vers les entrails de la bête.
Mon objectif est un peu différent.
Avec ces articles, je veux parler aux blueteams, ops, secops, devsecops, .*sec.*,  RSSI et autres ingénieurs en sécurité.
NixOS et la philosophie tout-as-code qui l'a enfantée, sont, j'en suis persuadé, les briques et le mortier des cyber-forteresses de demain.

Je vous propose donc de me suivre dans cette découverte de NixOS et de ses avantages en terme de sécurtié informatique.

- Challenges techniques
- Solutions actuelles et leurs limites
- Conceptes de base
- Cas pratique
- Comment NixOS répond à nos exigeances
- Les bonus en terme de sécurité
- Les inconvenients
- Conclusion

## Challenges techniques

Voici ce qui, à mon avis, est à l'origine de la majorité des problème de sécurité et de robustesse en général de nos systèmes d'information.

**Inexhaustivité de la cartographie :**
C'est le premier point que je met en avant parceque c'est, pour moi, le plus central.
Les systèmes d'information modernes ne cesses de se complexifier.
La visibilité des équipes d'administration sur leurs infrastructure est souvent très médiocre.
Il est difficile de dire quelles machines sont déployés, dans quel DC, et ce qui est installé dessus.
C'est un vrai problème pour la maintenabilité des parcs informatiques et donc la sécurité des réseaux.

**Entropie des configuration :**
En plus de ne pas avoir de tracabilité sur les configuration il est également très difficile de trouver des standard.
Dans les SI les plus anciens que j'ai pu voir, il y avait en général autant de configurations que de déploiement différent.
Chaque admin a ses habitudes et préférences.
Une même application peut être déployée un jour avec un paquet pip et le suivant par l'extraction d'une archive dans /opt.
Que ce soit pour la maintenabilité ou même la réponse à incident, sans normalisation, le métier d'ops devient vite un enfer.

**Gestion chaotique des patchs :**
Comme les configurations sont chaotiques, appliquer un patch de sécurité peut vite devenir une tâche herculéenne.
Même lorsque l'application du patch est simple, le manque de visibilité empêche toute certitude quand a sa robustesse.
Chaque mise en production qui touche un peu trop à l'infrastructure s'accompagne en général d'une peur bleu.
Celle de rencontrer des incompatibilité qui n'avaient pas été découvert dans les environnements de pré-production.

**Obscurité à l'audit :**
Je le vois dans mon activité actuelle, auditer un système est souvent plus compliqué qu'il ne devrait.
Cela se restrein en général à 3 méthode :
commenter un schéma d'architecture qui n'est souvent plus à jour;
analyser une poigner de fichiers de configuration hors context et qui ne sont pas représentatifs de la majorité de l'infra;
réaliser des exercices de pentest qui ne sont pas du tout exhaustifs.

**Automatisation complexe :**
Il est facile de sauvegarder le contenue d'une base de donnée ou le code source d'une application pour les restaurer en cas d'incident.
Il est plus difficile de restaurer une infrastructure entière avec ses VM, leurs systèmes de fichier et leur configuration exacte.
Les procédures de déploiement qui sont sensé être le garde fou dans ce genre de scénario sont souvent réputés incomplètes ou obsolètes.
Un moyen plus efficace est l'automatisation des process de déploiement.
Malheureusement, les technologies qu'on utilisent n'ont, pour la plupart, pas été pensés à l'origine pour être automatisé et intégrés aux échelles que l'on connais aujourd'hui.

## Solutions existantes

En général, les premières tentatives d'automatisation se font à l'aide de **scripts et/ou GPO**.
Cette solution est évidement très peu robuste et même si elle est facile à mettre en place pour des petits réseaux, elle est loin d'être scalable.
Bien souvent les scripts sont passé par des clefs usb ou par mail ou stocké sur un partage réseau (j'entend des RSSI tousser).
La gestion des versions est inexistante ou au moins chaotique et les tentatives de normalisation voués à l'écheque.

Une fois que le réseaux grossis, que les équipes gagnent en maturité (et qu'une/un DSI décide de bien vouloir allouer du budget), on voit apparaitre de **l'infra as code**. 
La mise en place de l'IAC peut parfois être très tatonnante mais c'est en général un grand pas vers la résiliance informatique.
Cependant, peut importe la technologie utilisée (Ansible, Terraform, Saltstack, ...) les technos se basent sur un état _virtuel_ du système.
La moindre modification manuel d'un admin qui ne serait pas reportée dans le code peut entrainer des heures, voir des jours de debuggage.
De plus, ceux qui ont déjà écris des recette ansible sauront qu'une grande partie (parfois la majorité) du temps peut être consacré à rendre les recettes idempotantes.

Enfin, il y à les **containers**.
Biensure la techno resoud beaucoup des problèmes dont nous avons parlé plus haut.
Seulement, cette solution n'est pas applicable partout, en particulier lorsqu'il s'agit de maintenir des infrastructures physiques.

## Le système parfait

Bien. Enumérons humblement les caractéristiques d'un système d'infrastructure as code _parfait_ d'après ce que l'on à vus :

* **automatisable :** une toolchain facile à manipuler doit permettre d'automatiser l'installation d'un système avec précision, sans interventions humaines.
* **versionnable :** il est possible de versionner entièrement la configuration du système (en plus des snapshots qui ne devraient s'intéresser qu'aux donnés).
* **auditable :** la lecture du fichier de code/configuration ne doit pas laisser de doutes quand à la configuration exacte du système entier.
* **feature-full :** toutes les fonctionnalités d'un systèmes classique doivent être retrouvée.
* **reproductibe & idempotant :** les mises à jours et/ou redéploiements sont déterministes et strictement idempotantes.

## Conceptes de base

### Nix Package Manager : Dérivation > ~~Package~~ 

Tous commence en 2006 avec une publication d'Eelco Dolstra.

[![](/assets/drafts/phd.png)](https://edolstra.github.io/pubs/phd-thesis.pdf)

Il y présente les principaux problèmes des gestionnaires de package traditionnels.
En particulier la difficultée croissante à gérer les dépendances (en particulier les dépendances cycliques) et la sensibilité aux changements cassant.
Pour y répondre, il propose un nouveaux model inspiré des languages fonctionnels.

Dans son model les paquets doivent avoir les mêmes propriété qu'on retrouve en programmation fonctionnel :

- imutabilité : une fois ~~instancié~~ installé, il n'est pas possible de modifier un package
- isolation : comme pour les fonctions, l'installation d'un package ne doit pas pouvoir impacter l'execution des autres
- déterminisme : les dépendances sont identifiés de façon exhaustive

On appellera un package avec ces propriété une **dérivation**.

![](/assets/drafts/drake.png){: width="500px" }

Cela change profondément l'approche traditionnel de l'administration système.
Avec tous les respect que je dois à la distribution Debian et tous ce qu'elle à apporté au monde de l'open source, dpkg est un enfer à manipuler.
Son historique énorme ne lui rend pas service.

Avec le principe de dérivation, oubliez les packages obsucre qui mélangent système de build inconnus, scriptes esotériques et variables d'environnement mystiques.
Les définitions de dérivations sont écrites dans une sytaxe clair et accessibles même aux novices.

### Nix Store

![](/assets/drafts/nixstore.png)

avant un .deb foutait des fichiers partout dans le système une fois installé
(binaire dans /usr/bin, lib dans /var/lib, ...)

la, on à tous qui est stocké dans /nix/store et chaque dérivation est représenté par un hash

le hash est la concatenation de toutes les sources nécessaire au build du packet et du hash de toutes les dérivations dont il dépend

```
DERIVATION = hash(hash(SRC) + hash(DEPENDANCES))
```

NOTES:

* dérivation => représenté par hash => intégrité
* également dérivations dont dépent => pour build => ou execution
* références les unes entre les autres => utilisant hash
* oublier => collision de nom => oeuvre d'un attaquant => ou simple accident.
* toutes stocké dans `/nix/store` => j'appellerais le nix store

### Faire le lien

```txt
[tristan@demo:~]$ gcc --version
gcc (GCC) 11.3.0

[tristan@demo:~]$ which gcc
/home/tristan/.nix-profile/bin/gcc

[tristan@demo:~]$ ls -l /home/tristan/.nix-profile/bin/gcc
/home/tristan/.nix-profile/bin/gcc -> /nix/store/ykcrnkiicqg1pwls9kgnmf0hd9qjqp4x-gcc-wrapper-11.3.0/bin/gcc
```

NOTES:

* encore un peu abstrait
* pointe vers un 'nix-profile'
* nix-profile => lien vers dérivation
* dérivation => liens vers nix store
* nixos = PM purement fonctionnel + liens + systemd

### Mirroir

![](/assets/drafts/github.png)

* dérivations simples à coder
* incroyable communauté => écrite + 80 000 dérivations
* installer tous vos packages préféré
* équivalent de mirroir APT => github
* nouveau mirroir => aussi simple que => fork

## Cas pratique

déploiement d'une application (type nextcloud) avec docker compose avant sur un système old-schoole type debian ou centos

1. écrire une dérivation pour le packet
2. ecrire le reste du code pour le système autour

### Situation initiale

```txt
├── docker-compose.yml
├── Makefile
└── template.env
```

* tourne => docker compose
* historiquement => debian ou centos
* passer sous nixos => philosophie "nix"

### "Talk is cheap, ..."

```nix
{pkgs, fetchFromGitHub, ...}: 
let
  argProjectName = "--project-name '$name'";
  argComposeFile = "--file '$src/docker-compose.yml'";
  dockercmd = "compose ${argProjectName} ${argComposeFile} up -d";
in
derivation {
  name = "docker-nextcloud";

  system = builtins.currentSystem;

  src = fetchFromGitHub {
    owner = "0b11stan";
    repo = "docker-nextcloud";
    rev = "main";
    sha256 = "sha256-Sh+9Apb71QJHeShgaUbqLXQJMEjrBfkY/tW4Piq7Kss=";
  };

  builder = "${pkgs.bash}/bin/bash";

  args = [ "-c"
    ''
      ${pkgs.coreutils}/bin/mkdir $out \
        && echo "${pkgs.docker}/bin/docker ${dockercmd}" \
        > $out/$name.sh \
        && ${pkgs.coreutils}/bin/chmod +x $out/$name.sh
    ''
  ];
}
```

* Prémière étape => écrire dérivation
* debian vous jouiez la commande suivante
  - docker compose 
  - -p => nom projet
  - -f => chemin fichier yaml
* coeur de dérivation => nom => participe hash 
* sources du packet => fetchfromgithub => builtin => dépôt => docker-compose.yaml
* résultat dérivation => script
* $out => variable => chemin => nix store
* mkdir chmod docker => objet pkgs => définis dépendances => replacer par path store

dérivation docker-nextcloud => 30aine de lignes

### Configurations

```nix
          ###   /etc/nixos/configuration.nix   ###

{config, lib, pkgs, ...}:
let
  secretMySQLRootPassword = builtins.getEnv "MYSQL_ROOT_PASSWORD";
  secretMySQLPassword = builtins.getEnv "MYSQL_PASSWORD";
in {
  imports = [./hardware-configuration.nix];

  ...

  system.stateVersion = "22.05";
}
```

NOTES:

* plus dure est déjà fait => reste configurer correctement système
* fichier => dans /etc/nixos/configuration.nix
* voyez => squelette => ajouter bloques => pour décrire système

### Configuration - Nextcloud

```nix
nixpkgs.overlays = [(self: super: {
  docker-nextcloud = super.callPackage ./docker-nextcloud.nix {};
})];

environment.systemPackages = [pkgs.docker-nextcloud];

systemd.services.nextcloud = {
  enable = true;
  restartIfChanged = true;
  wantedBy = ["multi-user.target"];
  after = ["docker.service"];
  bindsTo = ["docker.service"];
  documentation = ["https://github.com/0b11stan/docker-nextcloud"];
  script = "${pkgs.docker-nextcloud}/docker-nextcloud.sh";
  environment = {
    MYSQL_ROOT_PASSWORD = secretMySQLRootPassword;
    MYSQL_PASSWORD = secretMySQLPassword;
  };
};

```

NOTES:

* ajoute dérivation => aux sources autorisés => fichiers "release" debian
* rend accessible à l'entièreté du système
* enfin, on défini un service systemd
* qui sera déployé au démarrage
* qui execute le script généré par notre dérivation
* et le tous en donnant accès par exemlpe à secrets

### Configuration - Docker

```nix
  virtualisation.docker.enable = true;
```

### Configuration - SSH

```nix
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    permitRootLogin = "no";
  };
```

NOTES:

Pour l'administration, il est toujours possible d'activer ssh et de
configurer le service par la même occasion, en 5 lignes

### Configuration - Réseau

```nix
networking = {
  hostName = "nixos-harden";
  networkmanager.enable = true;
  useDHCP = true;
  firewall = {
    enable = true;
    allowedTCPPorts = [8080 22];
  };
};
```

NOTES:

* La configuration réseau tiens en 10 lignes
* firewall local => pas cli IPTABLE
* quand c'est aussi simple d'activer un firewall local => plus excuse

### Configuration - User

```nix
users.users = {
  tristan = {
    isNormalUser = true;
    extraGroups = ["wheel" "docker"];
    packages = [pkgs.neovim];
    openssh.authorizedKeys.keyFiles = [
      ./ssh-keys/silver-hp.pub
    ];
  };
};
```

NOTES:

* enfin, vous voudrez ajouter un ou plusieurs administrateur à votre système
* les ajouter dans des groupes
* leur installer des application isollées les uns des autres
* configurer leurs clefs SSH

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
