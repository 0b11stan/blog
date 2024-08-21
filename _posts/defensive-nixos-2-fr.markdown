---
title: Defensive Nixos (2/3) - Pratique
lang: fr
ref: defensive-nixos-2
---

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
