# D'Arch à Nixos

## Installation

Dans un premier temps, j'ai testé une installation sur qemu.

Création d'un disque de 10G vierge qui accueillera le système de test:
```bash
qemu-img create -f qcow2 templates/nixos.qcow2 10G
```

Installation de nixos:
```bash
qemu-system-x86_64 -enable-kvm -m 6G -hda templates/nixos.qcow2 -cdrom ~/isos/nixos-minimal-21.05.3709.781b1f8e3a2-x86_64-linux.iso -boot d &
vncviewer :5900 &
```

J'ai suivit [la partie "installation" du manuel utilisateur](https://nixos.org/manual/nixos/stable/#sec-installation).
L'installation est assez similaire de celle d'archlinux puisque le
partitionnement est à réaliser à la main mais une très large partie de la
configuration propre à nixos est prise en charge par la commande nixos-install.

## Configuration

Une fois le système installé, j'ai pu démarrer sur mon image pour accéder à un
shell bash tout simple.
```bash
qemu-system-x86_64 -enable-kvm -m 4G -hda templates/nixos.qcow2 &
vncviewer :5900 &
```

### Sway

Mon Windows manager de prédilection est Sway.

Deux ressources principales :
  * https://nixos.wiki/wiki/Sway
  * https://search.nixos.org/options?query=sway

Pas dingue, sway marchais pas, quand j'essayais de jouer sway dans le shell:

(capture d'écran sans qxl)

Finalement je comprend après beaucoup de recherche qu'il faut que j'essaie d'autres
cartes : https://wiki.archlinux.org/title/QEMU#Graphic_card

et du coup que j'install tout les drivers pour être sure https://search.nixos.org/options?query=allFirmware

(todo plus tard : n'installer que ceux qui sont nécessaires)
(vérifier si j'ai eu besoin d'installer les non free)

c'est mieux mais toujours pas ouf :

(capture d'écran de la variable manquante)

il faut faire comprendre à sway en fait que c'est normal qu'on souhaite faire
de l'emulation logiciel donc on doit exporter cette variable

après un test YES c'est bon:

(capture écran de sway qui fonctionne)

du coup par contre j'ai deux soucis : 

* sway est en qwerty
* comment je fait pour que ma config fix elle même la variable ?

la je comprend qu'il va y avoir de la lecture à faire donc je fais une recherche
de la doc 

le truc génial c'est [ce wiki](https://nixos.wiki/wiki/Main_Page) et évidement
[le manuel de nixos](https://nixos.org/manual/nixos/stable/)

mais le graal c'est surtout [la page resources](https://nixos.wiki/wiki/Resources)
du wiki qui contient toutes les infos
