{
  # Enable the X11 windowing system.
  services.xserver.enable = false;

  # Enable the GNOME Desktop Environment.
  # services.displayManager.gdm.enable = true;
  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "matrix";
      battery_id = "BAT0";
      bigclock = "en";
    };
  };
  services.desktopManager.gnome.enable = true;

  services.gvfs.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

}
