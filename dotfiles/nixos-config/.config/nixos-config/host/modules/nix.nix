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

  # Nix evaluator GC tuning — forces Boehm GC to release memory back to OS
  # Without this, freed heap memory stays as "used" (saves ~2-3 GB during eval)
  systemd.services.nix-daemon.environment = {
    GC_FORCE_UNMAP_ON_GCOLLECT = "1";
    GC_INITIAL_HEAP_SIZE = "256m";
  };

}
