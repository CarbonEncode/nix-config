# Shared applications for machines using the GNOME desktop profile.
{ pkgs, ... }:
{
  # Required by Steam and other proprietary desktop applications.
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vesktop # Discord desktop client with Vencord included
    deezer-desktop # Unofficial Deezer Linux port, packaged with Electron
    proton-pass
    vscodium
    vlc
    mpv
  ];

  # Includes 32-bit graphics, PipeWire ALSA compatibility, and controller rules.
  programs.steam.enable = true;

  # The wrapped stable Firefox package includes matching FFmpeg libraries.
  programs.firefox = {
    enable = true;
    preferencesStatus = "default";
    preferences."media.eme.enabled" = true;
  };

  xdg.mime.defaultApplications = {
    "text/html" = [ "firefox.desktop" ];
    "application/xhtml+xml" = [ "firefox.desktop" ];
    "x-scheme-handler/http" = [ "firefox.desktop" ];
    "x-scheme-handler/https" = [ "firefox.desktop" ];
  };
}
