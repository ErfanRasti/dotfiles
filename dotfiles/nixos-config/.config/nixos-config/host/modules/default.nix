{
  imports = [
    ./nix.nix # Nix daemon settings (gc, optimise, experimental-features)
    ./boot.nix # Boot config
    ./kernel.nix # Kernel packages (needed by nvidia)
    ./inputs.nix # Touchpad etc (lowest priority)
    ./networks.nix # Networking, hostname, firewall
    ./graphics.nix # GPU drivers (depends on boot.kernelPackages)
    ./hardware.nix # Hardware peripherals (Bluetooth, USB, etc.)
    ./services.nix # Desktop, display manager, xserver
    ./audio.nix # Audio hardware
    ./security.nix # Sudo, security policies
    ./users.nix # User accounts
    ./system.nix # System state version
    ./packages.nix # System packages, programs, unfree
    ./theme.nix # Theme
    ./swap.nix # Swap partition
    ./power.nix # Poewr management
    ./fonts.nix # Font packages
  ];
}
