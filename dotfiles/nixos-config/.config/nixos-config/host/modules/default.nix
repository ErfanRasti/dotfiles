{
  imports = [
    ./nix.nix # Nix daemon settings (gc, optimise, experimental-features)
    ./boot.nix # Boot config
    ./kernel.nix # Kernel packages (needed by nvidia)
    ./inputs.nix # Touchpad etc (lowest priority)
    ./networks.nix # Networking, hostname, firewall
    ./location.nix # GeoClue, its agent (follows GNOME's Location switch), app rules
    ./graphics.nix # GPU drivers (depends on boot.kernelPackages)
    ./hardware.nix # Hardware peripherals (Bluetooth, USB, etc.)
    ./services.nix # Desktop, display manager, xserver
    ./audio.nix # Audio hardware
    ./security.nix # Sudo, security policies
    ./users.nix # User accounts
    ./system.nix # System state version
    ./envvars.nix # Environment variables
    ./packages.nix # System packages, programs, unfree
    ./hyprland-plugins.nix # Hyprland plugins built against the system Hyprland
    ./theme.nix # Theme
    ./swap.nix # Swap partition
    ./power.nix # Poewr management
    ./fonts.nix # Font packages
  ];
}
