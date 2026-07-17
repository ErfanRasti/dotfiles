flake-overlays:
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
  ]
  ++ flake-overlays;
}
