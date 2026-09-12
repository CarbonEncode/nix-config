{ lib, hostSettings, ... }:
{
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  hardware.enableRedistributableFirmware = true;

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
