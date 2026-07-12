{
  description = "My system configuration";

  inputs = {

    # List your channels using: nix-channel --list
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";

      # Sync home-manager and nixpkgs packages
      # don't use your own pinned home-manager.nixpkgs; use mine instead
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-matlab = {
      # See https://gitlab.com/doronbehar/nix-matlab

      # nix-matlab's Nixpkgs input follows Nixpkgs' nixos-unstable branch. However
      # your Nixpkgs revision might not follow the same branch. You'd want to
      # match your Nixpkgs and nix-matlab to ensure fontconfig related
      # compatibility.
      inputs.nixpkgs.follows = "nixpkgs";
      url = "gitlab:doronbehar/nix-matlab";
    };

    figlet-fonts = {
      url = "github:xero/figlet-fonts/main";
      flake = false; # Since it's not a flake itself
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";

      # Optional but recommended to limit the size of your system closure.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia.url = "github:noctalia-dev/noctalia/cachix";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # nix-software-center.url = "github:snowfallorg/nix-software-center";
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs:

    let
      identity = import ./identity.nix;
      system = "x86_64-linux";
      username = identity.username;
      hostname = identity.hostname;
      stateVersion = "26.05";
      flake-overlays = [
        inputs.nix-matlab.overlay
      ];
    in
    {

      # Check the flakes in: nix flake show
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {

        specialArgs = {
          inherit
            inputs
            system
            username
            hostname
            stateVersion
            ;
        };

        modules = [
          ./host/configuration.nix
          inputs.lanzaboote.nixosModules.lanzaboote

        ];
      };

      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};

        extraSpecialArgs = {
          inherit inputs username stateVersion;
        };

        modules = [
          (import ./home-manager/home.nix flake-overlays)
        ];
      };
    };
}
