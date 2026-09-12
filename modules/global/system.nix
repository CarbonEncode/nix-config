{ config, lib, hostSettings, ... }:
{
  assertions = [
    {
      assertion = config.system.nixos.release == "26.05";
      message = "This configuration must use the NixOS 26.05 stable branch.";
    }
  ];

  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  hardware.enableRedistributableFirmware = true;

  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  time.timeZone = hostSettings.timeZone;
  i18n.defaultLocale = hostSettings.locale;
  services.xserver.xkb.layout = hostSettings.keyboardLayout;
  console.useXkbConfig = true;
  console.earlySetup = true;

  users.users.${hostSettings.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    # Password is set interactively, never stored in this project.
  };
  security.sudo.wheelNeedsPassword = true;
  security.tpm2.enable = false;

  # Only compressed RAM swap; never activate disk-backed swap.
  zramSwap.enable = true;
  swapDevices = lib.mkForce [ ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
