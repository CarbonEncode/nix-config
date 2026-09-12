{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk.nix
    ../../modules/desktop/gnome.nix
  ];

  # sekai-specific UEFI boot and Intel hardware.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.initrd.systemd.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.kernelModules = [ "xe" ];
  hardware.cpu.intel.updateMicrocode = true;
  hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];

  # Keep this tied to this machine's initial installation.
  system.stateVersion = "26.05";
}
