---
title: Defensive Nixos (2/3) - Pratique
lang: fr
ref: defensive-nixos-2
---

Bonjour et bienvenue dans ce 2e article sur les avantages cybersécurité de la distribution NixOS.

Le premier article restait très théorique et servait d'introduction aux conceptes de base de nix.
(Si vous ne l'avez pas encore lu, je vous conseille d'y [jeter un coup d'oeuil](https://blog.tic.sh/2024/09/24/defensive-nixos-1-en.html))
Nous allons maintenant rentrer un peu plus dans le vif du sujet pour s'attaquer à un cas pratique.

L'article se veux comme un guide pas à pas qui permet, en partant de zéro, de déployer un service web standard sur un serveur nix.
Bien évidement, je me contenterais d'un cas relativement simple, l'objectif étant de vous donner un appercu du process d'installation et de configuration de la distrib.
C'est également, et surtout, l'occasion de vous montrer à quel point NixOS est simple d'utilisation malgrès les conceptes sur lesquels il reposent qui peuvent parfois paraitres obscures au premier abord.

En guise de première application, j'ai choisi [gitea](https://about.gitea.com/).
Déployée dans de nombreuses organisations, cet équivalent de github écrit go en est très simple, performant et à la fois très complet en fonctionnalités.
Il peut fonctionner sur une simple base de donnée sqlite3 et c'est un choix relativement courant chez les [homelabers](https://www.reddit.com/r/homelab/).

Mais avant de s'attaquer à l'installation de notre github maison, il y à une étape essentiel, l'installation du serveur.

## Télécharger NixOS

La première étape, quand on commence n'importe quelle projet, c'est TOUJOURS de se rendre sur le site officiel.
Rendez-vous donc sur [nixos.org](https://nixos.org).

![](/assets/drafts/nixos-main-page.png)

Tant que vous y êtes, n'hésitez pas à consulter le site.
Il y à tout un tas de présentations très intéressantes et la communauté fait un vrai effort de communication pour vulgariser sans trahir les conceptes complexes qui font le coeur du système.

Pour ce qui est de l'installation détaillé du système, je vous présenterais un process d'installation simplifié qui se concentre sur le cas nominal.
Si vous voulez aller un peu plus loin, n'hésitez pas à consulter [l'excellent manuel officiel](https://nixos.org/manual/nixos/stable/).

Assez naturellement, comme pour la majorité des systèmes d'exploitation, la première étape va être de télécharger l'ISO d'installation.
Pour notre server nixos nous n'avons pas besoin d'interface graphique, allons
donc directement récupérer [l'image minimale](https://channels.nixos.org/nixos-24.05/latest-nixos-minimal-aarch64-linux.iso) en bas de la page.

![](/assets/drafts/nixos-download-page.png)

Pour les plus consiencieux, il est toujours bon de tester le SHA256 de l'image.

![](/assets/drafts/download-and-check-hash.png)

## Préparer la VM

Pour tester notre poc on va évidement utiliser une machine virtuelle.
L'hyperviseur que j'utilise principalement est qemu/kvm mais bien évidement vmware ou virtualbox fonctionneront tout aussi bien.
Je vous invite donc à lire les commentaire suivant et adapter à votre environnement.
(attention, je n'utilise pas UEFI ici, le process d'installation serait un peu différent)

```bash
# initialisation de notre image de vm, 
qemu-img create -f qcow2 nixos-demo.qcow2 15G

qemu-system-x86_64 \
    # configuration réseau très simple avec forwarding du port ssh
    -netdev user,id=net0,hostfwd=tcp::2222-:22 -device virtio-net,netdev=net0 \
    # utilisation de kvm et du driver graphique virtio pour la performance
    -enable-kvm -vga virtio \
    # 4G de mémoire et 4 vcpu sont largement suffisant pour nos besoins
    -m 4G -smp cpus=4 \
    # l'ISO est chargé et l'emplacement cdrom est choisie comme boot par défaut
    -cdrom nixos.iso -boot d -hda nixos-demo.qcow2

```

Une fois que la machine à démarrer et que vous arriver sur l'écran du bootloader, choisissez, comme d'habitude, la première option.

![](/assets/drafts/install-screen.png)

Et la, terreur, voila que vous arrivez sur un shell.
J'ai choisi de vous montrer l'installation en ligne de commande parceque pendant longtemps c'était la seul disponible et c'est aussi celle qui permet le plus de flexibilité.
Pour ceux qui n'ont encore jamais installé de distribution linux "a la main", rassurez-vous il n'y à rien d'insurmontable.
Pour les habitué des install ArchLinux (btw), vous allez être décus, c'est beaucoup plus simple.

La grande majorité de l'installation se fait avec les droits root.
Donc même si c'est une mauvaise pratique sur un système de prod, on est la sur un système qui n'est même pas encore installé.
Epargnez-vous un peu et jouez la commande `sudo -i` pour vous octroyer les privilèges admin à long terme.

La commande `loadkeys fr` permet de charger le clavier par défaut (qwerty) en clavier clavier azerty français.
_A adapter en fonction du besoin (man loadkeys), et si vous utilisez un clavier qwerty, pas besoin de jouer cette commande évidement._

La 3ème _et dernière_ commande à jouer dans la fenêtre de votre hyperviseur, c'est `passwd`, pour changer le mot de passe de l'utilisateur root.

![](/assets/drafts/initial-commands.png)

Une fois que vous avez joué cette dernière commande `passwd`, vous allez pouvoir quitter l'écran tout pourris de votre hyperviseur géré par un vieux driver VGA sans option de resize et qui ne supporte probablement pas le moindre copiez-coller.
Le reste de l'installation pourra se faire en SSH depuis votre hôte \o/.

![](/assets/drafts/first-ssh-connection.png)

Pour s'éviter de mauvaises surprises plus tard, commencez par vérifier que vous avez bien accès à internet depuis votre VM.

![](/assets/drafts/verify-connectivity.png)

## Partitionnement et Formatage

Ensuite, étape importante et souvent rendue obscure par les installation GUI, le partitionnement.
Pour cette installation simpliste je me contente du stricte minimum : deux partitions primaires.

- la partition principale que l'on rend bootable et compatible avec le BIOS legacy qu'on utilise sur cette VM
- la partition de swap, plus courte mais obligatoire, qui servira de partition d'échange pour libérer de la RAM

Ce n'est clairement pas le sujet de cet article mais si vous souhaitiez ajouter du chiffrement de disque ou utiliser des volumes logiques (type LVM), c'est le moment ;)

![](/assets/drafts/create-partitions.png)

Les partitions doivent ensuite être formatés.
La majorité des formats de systèmes de fichiers connus sous linux sont supportés par NixOS.
J'ai choisis ext4 parceque c'est le standard mais libre à vous d'essayer des formats plus exotiques comme zfs.

![](/assets/drafts/formate-partitions.png)

Notre nouvelle partition peut maintenant être monté.
En général on utilise le dossier `/mnt` réservé justement à ce genre de cas.
Il faut également activer le swap, ça nous facilite une étape plus tard ;)

![](/assets/drafts/mount-filesystem.png)

## Génération de la configuration initial

Aaaah, nous voila dans l'étape la plus intéressante.
Jusqu'ici toutes les étapes ressemblait beaucoup à une installation manuelle classique de n'importe quelle distribution linux de base.
On va bientôt commencer à toucher à de la configuration `nix`, ça vous excite hein ? Non ? Moi oui !

Vu que c'est une première installation faisons les choses dans l'ordre.
NixOS c'est de l'OS as code, on dis aussi **"système de configuration déclaratif"**.
Ca veux dire que toute la configuration du système est écrite dans un ou plusieurs fichiers, et ceux, dès le début !
Changer le système c'est simplement éditer ces fichiers de configuration et les réapliquer avec une ligne de commande.

Bon c'est bien beaux mais pour l'instant on à aucune idée de la tête qu'elle à cette configuration nix.
Heureusement, NixOS fournis une commande `nixos-generate-config` qui va permettre de générer un template pour nous.
Cette commande prend en paramètre la racine de notre nouveau système (le fameux `/mnt` que l'on à préparé juste avant).

![](/assets/drafts/initial-config.png)

La commande génère 2 fichiers :

- `configuration.nix` : c'est le fichier principale, la ou la majorité de la configuration sera rassemblée
- `hardware-configuration.nix` : contient tout ce qui est spécifique au materiel

Ce qui est très intéressant avec la commande `nixos-generate-config` c'est surtout ce dernier fichier relatif au hardware.
Jettez-y un coup d'oueil (`cat /mnt/etc/nixos/hardware-configuration.nix`), vous verrez que le programme à détecté tous seul plein de détail sur notre configuration :

- le fait qu'on se trouve dans une VM et le type d'hyperviseur que l'on utilise
- le nom du disque principale sur lequel sera installé le système
- le partitionnement que l'on veux utiliser (pour le swap et le root)
- il en à même déduit les modules noyaux à utiliser (si vous aviez utilisé lvm, le module correspondant apparaitrait)

Biensure, le fichier `configuration.nix` est également un excellent point de départ pour construire notre configuration.
Histoire d'adopter directement les bonnes pratiques, on va récupérer cette base de travail en local pour la modifier plus facilement.

![](/assets/drafts/get-initial-config.png)

Il y à un tas de commentaires très utiles que je vous encourage à lire pour avoir une petite idée des options qui s'offres à vous.
N'hésitez pas à tester ces options, que ce soit maintenant ou après l'installation du système à proprement parler.

Je vais maintenant vous proposer ma version d'une configuration minimale de nixos après avoir modifier les fichiers de base.
Notre service final (gitea) n'est pas encore installé biensure et je vous conseil de faire de même.
Concentrons nous d'abord sur l'installation du système en lui même, le reste viendra après.


les seules modification qui ont été faites :

- suppression des commentaires
- adaptation de certaines options (timezone, grub.device, users, ...)
- changement du nom des disques pour utiliser des labels
- ramener options networking dans configuration
- ramener options boot dans hardware

### configuraton.nix

```nix
{ config, lib, pkgs, ... }: {
  imports = [./hardware-configuration.nix];

  networking = {
    hostName = "guest";
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
  };

  time.timeZone = "Europe/Paris";

  console = {
    font = "Lat2-Terminus16";
    keyMap = "fr";
  };

  users.users.tristan = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    packages = [];
  };

  services.openssh.enable = true;

  system.copySystemConfiguration = true;
  system.stateVersion = "24.05"; # DO NOT MODIFY
}
```

La première chose que l'on peut noter est sur la forme.
Le language nix qui sert à la configuration est en fait bien plus qu'un simple format de fichier de conf, c'est un véritable language.
Je vous l'accorde, le language n'a pas vraiment un aspect habituel mais c'est parceque c'est un [language purement fonctionnel](https://en.wikipedia.org/wiki/Purely_functional_programming).
On ne vas pas rentrer dans les détail de ce qu'es un language fonctionnel pure même si le sujet est très intéressant.
Pour de la configuration de base, il n'est absolument pas nécessaire d'être un expert du code ou même de faire la différence entre paradigme fonctionnel ou procédural.
Gardez simplement à l'esprit qu'il est possible d'aller vraiment très loin dans la finesse de spécification et dans la complexité de construction d'une configuration nix.

(pour les plus curieux, ce que vous avez devant vous est en fait une fonction anonyme : `{ arguments } : { sortie => dictionnaire }`, la [documentation officiel de nix](https://nix.dev/manual/nix/2.18/language/index.html) vous en dira plus)

Une fois que la forme est comprise, le fond est assez évident.
Je ne détaillerais que les points que 3 points.

L'utilisation de l'attribut `imports` qui permet d'intégrer à notre configuration le fichier `hardware-configuration.nix`.
Cette pratique de diviser la configuration abstraire de tout ce qui à avoir avec le materiel n'est pas obligatoire mais elle est chaudement conseillé.
Cela permet de faciliter la réutilisation de la configuration sur des materiels différents.
Une fois qu'il faudra passer notre serveur gitea en production sur un serveur physique ou sur un hyperviseur VMWare par exemple, seul le fichier `harware-configuration.nix` aura besoin de changer.

L'expression `lib.mkDefault true` que vous pouvez ignorer pour l'instant mais qui est utilisée [pour forcer](https://discourse.nixos.org/t/what-does-mkdefault-do-exactly/9028) l'utilisation du DHCP (qui est positionné à `false` par NetworkManager sinon).

Plus important : l'attribut `<users>.packages` qui permet de définir les packets qui sont attachés à chaque utilisateur.
J'ai laissé apparaitre cette dernière option même si elle est vide parcequ'elle permet d'insister sur quelque-chose d'important.
Sur NixOS, chaque utilisateur à accès à un sous ensemble restreint de packet.
Une base de packet ([les coreutils](https://www.gnu.org/software/coreutils/coreutils.html) notemment) est évidemment accessible à tous les utilisateurs.
Cependant, si vous spécifiez `netcat` dans l'attribut `packages` de l'utilisatrice `alice` par exemple, alors alice aura `netcat` dans son `PATH`, mais pas `bob`.
Dans NixOS, la séparation des périmètres, c'est _by design_.

### hardware-configuration.nix

```nix
{ config, lib, pkgs, modulesPath, ... }: {
  imports = [(modulesPath + "/profiles/qemu-guest.nix")];

  boot = {
    initrd.availableKernelModules = ["ata_piix" "floppy" "sd_mod" "sr_mod"];
    initrd.kernelModules = [];
    kernelModules = [];
    extraModulePackages = [];
    loader.grub.enable = true;
    loader.grub.device = "/dev/sda";
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  swapDevices = [
    {device = "/dev/disk/by-label/swap";}
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
```

Pour ce qui est de la configuration hardware, le détail le plus important à noter est l'utilisation des label de système de fichier.
Par défaut, NixOS génèrera un fichier qui identifie vos disques avec leur UUIDs.
Il est conseillé de modifier ces UUID avec les labels comme utilisé ci-dessus.
Cette technique permet d'améliorer grandement la portabilité de vos configurations nix.
Il suffira simplement d'utiliser les même label de partition lors du formatage pour vos prochaines installation et vous n'aurez quasiment rien à modifier dans le fichier hardware-configuration.nix.
Dans notre cas cela représente peu de ligne mais pour des systèmes qui ont un particionnement relativement compliqué, cela représente beaucoup d'économie.

## Installation du système

Maintenant que l'on à écris notre première configuration nix, on peu l'envoyer sur la VM et l'appliquer.

![](/assets/drafts/upload-n-install.png)

Cette commande peut être relativement longue en fonction de votre bande passante et de la configuration que vous avez demander de mettre en place.
Cependant ne restez pas trop loin de votre clavier puisqu'à la fin de l'installation, il vous sera demandé de choisir un mot de passe pour le compte root.

![](/assets/drafts/passwd-root.png)

En option, je vous recommande également de changer le mot de passe du nouvel utilisateur qui vient d'être créé.

![](/assets/drafts/passwd-user.png)

Et voila, l'installation de votre première machine est enfin terminée.
Vous pouvez éteindre l'instance d'installation.

```bash
shutdown now
```

## Démarrage de NixOS

```bash
sudo qemu-system-x86_64 \
    # la configuration réseau change, on va avoir besoin de forward les ports 80 et 443
    -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::3000-:3000 \
    -device virtio-net,netdev=net0 \
    # pour le reste la configuration est la même, on à juste retiré l'ISO
    -enable-kvm -display none -m 4G -smp cpus=4 -hda nixos-demo.qcow2
```

![](/assets/drafts/grub.png)

![](/assets/drafts/login.png)

![](/assets/drafts/ssh-hostkey.png)

![](/assets/drafts/ssh-defaults.png)

![](/assets/drafts/ssh-login.png)

## Installation de gitea

```bash
man --pager=cat configuration.nix | grep '^ *....services.gitea'
```

```nix
services.gitea = {
    enable = true;
    appName = "NixOS Demo";
};
```

utilisateur ne peux plus accéder à /etc/configuration en ssh mais pas grave

```bash
ssh -p 2222 tristan@localhost mkdir /home/tristan/system/
scp -rP 2222 src/*.nix tristan@localhost:/home/tristan/system/
```

![](/assets/drafts/non-default-config.png)

![](/assets/drafts/service-starting.png)

![](/assets/drafts/gitea-port-open.png)

http://localhost:3000

By playing the command `sudo journalctl -kf` and running your request

```text
Nov 21 22:06:24 guest kernel: refused connection: IN=ens3 OUT= MAC=52:54:00:12:34:56:52:55:0a:00:02:02:08:00 SRC=10.0.2.2 DST=10.0.2.15 LEN=44 TOS=0x00 PREC=0x00 TTL=64 ID=6896 PROTO=TCP SPT=55392 DPT=3000 WINDOW=65535 RES=0x00 SYN URGP=0
```

![](/assets/drafts/iptables-before.png)

could be tempted to add a rule by hand but you're in a nix env and it must be simpler

`man configuration.nix` look for `firewall`

![](/assets/drafts/allowed-ports.png)

```nix
networking = {
    hostName = "guest";
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
    firewall.allowedTCPPorts = [3000];
};
```

```bash
# on host
scp -rP 2222 src/*.nix tristan@localhost:/home/tristan/system/

# on guest
sudo nixos-rebuild switch -I nixos-config=/home/tristan/system/configuration.nix
```

![](/assets/drafts/iptables-after.png)

![](/assets/drafts/gitea-browser.png)

pour tester il suffit de se créer un compte (le premier compte est automatiquement administrateur) et c'est parti

## Test de la config


---

Pour déployer un serveur nextcloud en général sur un serveur géré avec ansible par exemple on aura 3 étapes



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




## conclusion

invite à tester sur VM


```bash
# ON THE HOST

curl --location --output nixos.iso 'https://channels.nixos.org/nixos-24.05/latest-nixos-minimal-x86_64-linux.iso'
curl --location --output nixos.iso.sha256 'https://channels.nixos.org/nixos-24.05/latest-nixos-minimal-x86_64-linux.iso.sha256'
sed -i 's/nixos.*iso/nixos.iso/' nixos.iso.sha256
sha256sum --check nixos.iso.sha256

qemu-img create -f qcow2 nixos-demo.qcow2 15G
qemu-system-x86_64 \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 -device virtio-net,netdev=net0 \
    -enable-kvm -vga virtio \
    -m 4G -smp cpus=4 \
    -cdrom nixos.iso -boot d -hda nixos-demo.qcow2

# ON THE GUEST

sudo -i
loadkeys fr
passwd

# ON THE HOST

ssh -p 2222 root@localhost
ping -4 -c 1 -w 1 wikipedia.org
parted /dev/sda -- mklabel msdos
parted /dev/sda -- mkpart primary 1MB -2GB
parted /dev/sda -- set 1 boot on
parted /dev/sda -- mkpart primary linux-swap -2GB 100%
mkfs.ext4 -L nixos /dev/sda1
mkswap -L swap /dev/sda2
mount /dev/disk/by-label/nixos /mnt
swapon /dev/sda2
nixos-generate-config --root /mnt
mkdir src
scp -rP 2222 root@localhost:/mnt/etc/nixos/ src/
vim src/* # edit the config
scp -rP 2222 src/*.nix root@localhost:/mnt/etc/nixos
ssh -p 2222 root@localhost
nixos-install # you have to enter root's password at the end
nixos-enter --root /mnt -c 'passwd tristan'
shutdown now
qemu-system-x86_64 \
    -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:8080,hostfwd=tcp::8443-:8443 \
    -device virtio-net,netdev=net0 \
    -enable-kvm -vga virtio -m 4G -smp cpus=4 -hda nixos-demo.qcow2
sed -i '/localhost/d' ~/.ssh/known_hosts
ssh -p 2222 tristan@localhost mkdir /home/tristan/configuration/
scp -rP 2222 src/*.nix tristan@localhost:/home/tristan/configuration/
ssh tristan@localhost
sudo nixos-rebuild switch -I nixos-config=/home/tristan/system/configuration.nix
```
