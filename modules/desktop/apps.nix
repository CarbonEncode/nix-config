# Shared applications for machines using the GNOME desktop profile.
{ pkgs, ... }:
{
  # Required by Vivaldi, its codecs, and Steam.
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vesktop # Discord desktop client with Vencord included
    deezer-enhanced # Unofficial Deezer desktop client for Linux
    proton-pass
    (vivaldi.override {
      proprietaryCodecs = true;
      vivaldi-ffmpeg-codecs = pkgs.vivaldi-ffmpeg-codecs;
    })
    vscodium
  ];

  # Includes 32-bit graphics, PipeWire ALSA compatibility, and controller rules.
  programs.steam.enable = true;

  xdg.mime.defaultApplications = {
    "text/html" = [ "vivaldi-stable.desktop" ];
    "x-scheme-handler/http" = [ "vivaldi-stable.desktop" ];
    "x-scheme-handler/https" = [ "vivaldi-stable.desktop" ];
  };
}
