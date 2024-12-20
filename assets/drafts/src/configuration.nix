{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [./hardware-configuration.nix];

  networking = {
    hostName = "guest";
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
    firewall.allowedTCPPorts = [3000];
  };

  time.timeZone = "Europe/Paris";

  console = {
    font = "Lat2-Terminus16";
    keyMap = "fr";
  };

  users.users.tristan = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    packages = with pkgs; [];
  };

  services.openssh.enable = true;

  services.gitea = {
    enable = true;
    appName = "NixOS Demo";
  };

  system.copySystemConfiguration = true;
  system.stateVersion = "24.05"; # DO NOT MODIFY
}
