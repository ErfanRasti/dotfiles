{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # https://nixos.wiki/wiki/Storage_optimization
  nix.optimise.automatic = true;
  nix.optimise.dates = [ "03:45" ]; # Optional; allows customizing optimisation schedule

  # Garbage Collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

}
