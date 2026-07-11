{ inputs, ... }: {
  imports = [
    ./packages.nix
    ./themes.nix
    ./desktop-entries.nix
    inputs.spicetify-nix.homeManagerModules.default
    ./spicetify.nix
  ];
}
