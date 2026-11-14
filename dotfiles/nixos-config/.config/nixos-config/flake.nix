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

    # Spicetify theme and extensions (see home-manager/modules/spicetify.nix)
    spicetify-comfy = {
      url = "github:Comfy-Themes/Spicetify";
      flake = false;
    };
    spicetify-adblock = {
      url = "github:rxri/spicetify-extensions";
      flake = false;
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";

      # Optional but recommended to limit the size of your system closure.
      inputs.nixpkgs.follows = "nixpkgs";
      # Its own rust-overlay pin uses stdenv.isLinux/isDarwin (evaluation warnings
      # on current nixpkgs); use an up-to-date one instead.
      inputs.rust-overlay.follows = "rust-overlay";
    };

    # Rust toolchain for building lanzaboote (see above).
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # GNOME Circle membership list (data/apps.json), see home-manager/modules/gnome-circle.nix.
    # `nix flake update gnome-circle` picks up apps added to or removed from Circle.
    gnome-circle = {
      url = "gitlab:Teams/Circle?host=gitlab.gnome.org";
      flake = false;
    };

    # Nautilus extensions missing from nixpkgs (see home-manager/modules/nautilus.nix).
    # They track upstream: `nix flake update` moves them to the latest commit.
    actions-for-nautilus = {
      url = "github:bassmanitram/actions-for-nautilus";
      flake = false;
    };
    nautilus-admin-gtk4 = {
      url = "github:MacTavishAO/nautilus-admin-gtk4";
      flake = false;
    };
    nautilus-checksums = {
      url = "git+https://gitlab.gnome.org/madmurphy/nautilus-checksums.git";
      flake = false;
    };
    nautilus-image-converter = {
      url = "git+https://gitlab.gnome.org/coreyberla/nautilus-image-converter.git";
      flake = false;
    };
    nautilus-share = {
      url = "git+https://gitlab.gnome.org/coreyberla/nautilus-share.git";
      flake = false;
    };

    gsr-ui-nix = {
      url = "github:rPlakama/gsr-ui-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # `follows` so it doesn't pull its own copy of nixpkgs.
    nix-software-center = {
      url = "github:snowfallorg/nix-software-center";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # No `follows`: on the main nixpkgs its dwarfs dependency fails its tests.
    app-manager.url = "github:kem-a/AppManager";

    # claude
    # No `follows`: it still uses nodePackages, which current nixpkgs removed.
    claude-desktop.url = "github:k3d3/claude-desktop-linux-flake";
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs:

    let
      identity = import ./identity.nix;
      system = "x86_64-linux";
      username = identity.username;
      hostname = identity.hostname;
      stateVersion = "26.05";
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
          inherit
            inputs
            username
            stateVersion
            system
            ;
        };

        modules = [
          (import ./home-manager/home.nix)
        ];
      };
    };
}
