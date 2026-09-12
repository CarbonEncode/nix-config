# Reusable desktop profile: import this on machines that should run GNOME.
{ pkgs, ... }:
{
  imports = [ ./extensions.nix ];

  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  services.gnome.core-apps.enable = false;
  services.gnome.games.enable = false;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.gnome-remote-desktop.enable = false;
  services.gnome.gnome-user-share.enable = false;
  services.gnome.rygel.enable = false;

  # Keep the normal GNOME settings, keyring, portals and removable-drive
  # integration, with a small selection of everyday applications.
  environment.systemPackages = with pkgs; [
    firefox
    nautilus
    gnome-console
    gnome-text-editor
    loupe
    papers
    file-roller
  ];
  programs.gnome-disks.enable = true;
  programs.seahorse.enable = true;
  programs.bash.vteIntegration = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  hardware.graphics.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  services.printing.enable = true;
  services.avahi.nssmdns4 = true;
  fonts.enableDefaultPackages = true;
}
