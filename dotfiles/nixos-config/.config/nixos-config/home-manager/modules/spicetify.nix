{ inputs, pkgs, ... }:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  programs.spicetify = {
    enable = true;

    theme = spicePkgs.themes.sleek;

    enabledExtensions = with spicePkgs.extensions; [
      fullAppDisplay
      shuffle
      adblockify
      hidePodcasts
    ];
  };
}
