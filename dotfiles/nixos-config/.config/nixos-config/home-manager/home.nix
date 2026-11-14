{
  stateVersion,
  username,
  inputs,
  ...
}:
{
  imports = [
    ./modules
  ];

  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = stateVersion;
  };

  nixpkgs.overlays = [
    inputs.nix-matlab.overlay
    # nix-matlab's library list, minus gtk2 and the deprecated xorg names (see matlab-libs.nix).
    (final: prev: {
      matlab = prev.matlab.override {
        targetPkgs = import ./modules/matlab-libs.nix inputs;
      };
    })
  ];
}
