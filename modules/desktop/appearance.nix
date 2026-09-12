# Editable GNOME defaults shared by desktop users.
{ ... }:
let
  wallpaper = ./assets/default-wallpaper.jpg;
  wallpaperUri = "file://${wallpaper}";
in
{
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/desktop/background" = {
          picture-uri = wallpaperUri;
          picture-uri-dark = wallpaperUri;
          picture-options = "zoom";
        };
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
        "org/gnome/desktop/wm/preferences" = {
          button-layout = "appmenu:minimize,maximize,close";
        };
      };
    }
  ];
}
