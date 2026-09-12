{ pkgs, ... }:
let
  # Add extensions here; the same list installs and enables them by default.
  extensions = with pkgs.gnomeExtensions; [
    dash-to-dock
    blur-my-shell
    applications-menu
  ];
in
{
  environment.systemPackages = extensions ++ [ pkgs.gnome-extension-manager ];
  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        # Defaults remain editable in GNOME Extension Manager.
        settings."org/gnome/shell" = {
          disable-user-extensions = false;
          enabled-extensions = map (extension: extension.extensionUuid) extensions;
        };
      }
    ];
  };
}
