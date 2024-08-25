---
title: Defensive Nixos (1/3) - Intro
lang: fr
ref: defensive-nixos-1
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

Pour continuer dans le parallèle avec debian, prenez un `.deb`.
Une fois installé, le paquet installe un tas de fichiers partout dans le système
(binaires dans `/usr/bin`, les librairies dans `/var/lib`, ...).
Même s'il y a un semblant d'ordre et que du tooling à été créé pour faciliter la vie il reste fastidieux de savoir exactement que paquet est à l'origine de quel fichier
(sans parler des conflits quand 2 paquets veulent écraser le même fichier).

![](/assets/drafts/nixstore.png)

Avec NixOS plus besoin de chercher ou sont quels fichiers et à qui ils appartiennent.
Tout (ou presque) est stocké dans `/nix/store` (exemple juste au dessus avec llvm).
Ici, chaque dérivation est représenté par un hash.
Ce hash est _approximativement_ la concaténation de toutes les sources nécessaires au build du paquet du hash de toutes les dérivations dont il dépend.

```
HASH_DERIVATION ~= hash(hash(SRC) + hash(DEPENDANCES))
```

Ce fonctionnement permet de garantire l'intégrité et l'immutabilité totale de tous les paquets et de leurs dépendances jusqu'aux briques les plus élémentaires.
(un peu à la manière d'une chaine de block pour les cryptoaddicts).
On peut oublier par le même coup les problèmes de collision de nom que ce soit par un simple accident (2 paquets qui ont le même nom)
ou à cause d'un attaquant qui voudrait s'amuser avec du path hijack et autres joyeusetés.

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

### Système As Code

...
