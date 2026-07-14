{ pkgs, ... }: {
  # sudo visudo
  security.sudo.extraConfig = ''
    Defaults env_keep += "http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ftp_proxy no_proxy"
  '';

  # `oomd`
  # https://search.nixos.org/options?channel=unstable&query=systemd.oomd
  # systemd.oomd = {
  #   enable = true;
  #   enableUserSlices = true; # protects system, manages user processes
  #   # enableSystemSlice = false;    # default, fine to leave
  #   # enableRootSlice = false;      # default, fine to leave
  #   settings.OOM = {
  #     SwapUsedLimitPercent = 80; # act when 80% swap is used
  #     MemoryUsedLimitPercent = 80; # act when 80% RAM is used
  #   };
  # };

  # `earlyoom`
  # https://search.nixos.org/options?channel=unstable&query=services.earlyoom
  services.earlyoom = {
    enable = true;

    # Thresholds (in % of free memory/swap)
    # These are quite aggressive (good for desktops) — adjust based on your RAM amount
    freeMemThreshold = 20; # Send SIGTERM when free RAM drops below 10%
    freeSwapThreshold = 20; # ...and free swap also below 10%

    # Harder kill thresholds (SIGKILL)
    freeMemKillThreshold = 5; # Force kill with SIGKILL below 5% free RAM
    freeSwapKillThreshold = 5; # Force kill with SIGKILL below 5% free swap

    # Extra command-line arguments (most important for desktop UX)
    extraArgs = [
      # "-g"                          # Kill entire process group (recommended for browsers/Electron)

      # Protect critical desktop processes (never kill these)
      "--avoid"
      "^(X|plasma.*|kwin|kde.*|gnome.*|Hyprland|sway|waybar|dbus|systemd|init|Xorg|ssh|pipewire|pulseaudio|wireplumber)$"

      # Prefer killing heavy memory hogs (common culprits)
      # "--prefer"
      # "^(electron|firefox|zen|chromium|brave|libreoffice|gimp|inkscape|discord|steam|qemu|virt-manager)$"
    ];

    # Optional but recommended
    enableNotifications = true; # Show desktop notification when something is killed
    enableDebugInfo = false; # Set to true only when troubleshooting
    reportInterval = 3600; # Print memory report to journal every 3600s (0 = disable)
  };

  # `apparmor`
  # https://search.nixos.org/options?channel=unstable&query=apparmor
  services.dbus.apparmor = "enabled";
  security.apparmor = {
    enable = true; # Activate AppArmor MAC; requires reboot after initial enable

    enableCache = false; # Whether to enable caching of AppArmor policies in `/var/cache/apparmor/`.
    # Disable cache: profile contents contain Nix store paths,
    # so cached versions accumulate rapidly on each rebuild

    # Kill processes that violate AppArmor profile instead of just logging
    # This enforces strict security rather than permissive mode
    killUnconfinedConfinables = true;

    # Apply AppArmor profiles to all packages installed in the system closure
    # Automatically loads profiles from /nix/store for every package
    packages = [ pkgs.apparmor-profiles ];

  };

  # Enable AppArmor confinement for systemd services by default
  # Any service without a profile will be blocked from starting
  #systemd.services."*".serviceConfig.AppArmorProfile = true;

  # Enable sshd using
  # services.openssh = {
  #   enable = true;
  #   openFirewall = true;
  # };

  # polkit status
  security.polkit.enable = true;
}
