{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
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
