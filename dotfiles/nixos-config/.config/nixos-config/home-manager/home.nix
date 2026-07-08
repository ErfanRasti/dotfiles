flake-overlays: { stateVersion, username, ... }: {
  imports = [
    ./modules
  ];

  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = stateVersion;
  };

  # Setup flake-overlays for MATLAB
  nixpkgs.overlays = [
    (final: prev: {
      # Your own overlays...
    })
  ]
  ++ flake-overlays;
}
