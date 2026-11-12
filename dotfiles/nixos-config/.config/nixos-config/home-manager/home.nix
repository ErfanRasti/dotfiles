{
  stateVersion,
  username,
  pkgs,
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
    (final: prev: {
      # Your own overlays...
      # https://wiki.nixos.org/wiki/Nautilus#Gstreamer
      nautilus = prev.nautilus.overrideAttrs (nprev: {
        buildInputs =
          nprev.buildInputs
          ++ (with pkgs.gst_all_1; [
            gst-plugins-good
            gst-plugins-bad
          ]);
      });
    })
    inputs.nix-matlab.overlay
    # nix-matlab's library list, minus gtk2 and the deprecated xorg names (see matlab-libs.nix).
    (final: prev: {
      matlab = prev.matlab.override {
        targetPkgs = import ./modules/matlab-libs.nix inputs;
      };
    })
  ];
}
