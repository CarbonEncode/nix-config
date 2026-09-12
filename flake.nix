{
  description = "NixOS machines with shared system tools and an optional GNOME desktop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, disko, ... }:
    let
      mkHost = hostname: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs.hostSettings = import ./hosts/${hostname}/settings.nix;
        modules = [
          disko.nixosModules.disko
          ./modules/global
          ./hosts/${hostname}
          { networking.hostName = hostname; }
        ];
      };
    in
    {
      nixosConfigurations = {
        sekai = mkHost "sekai";
        # Register future hosts here after adding their hosts/<name>/ files.
      };
      # Use the same pinned Disko for installation and configuration.
      packages.x86_64-linux.disko = disko.packages.x86_64-linux.disko;
    };
}
