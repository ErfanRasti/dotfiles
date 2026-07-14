{ hostname, ... }: {
  # See https://wiki.nixos.org/wiki/Networking

  networking.hostName = hostname; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";
  services.automatic-timezoned.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  networking.networkmanager.settings = {
    "device-mac-randomization" = {
      "wifi.scan-rand-mac-address" = true;
    };
    "connection-mac-randomization" = {
      "ethernet.cloned-mac-address" = "random";
      "wifi.cloned-mac-address" = "random";
    };
  };

  # Enable ufw firewall
  networking.firewall.enable = true;

  networking.nftables.enable = true;

  # Make nix-daemon inherit proxy settings from the environment
  # This will pick up http_proxy, https_proxy, etc. from your shell
  systemd.services.nix-daemon.environment = {
    # Use built-in environment variable passthrough

    # http_proxy = builtins.getEnv "http_proxy";
    # https_proxy = builtins.getEnv "https_proxy";
    # HTTP_PROXY = builtins.getEnv "HTTP_PROXY";
    # HTTPS_PROXY = builtins.getEnv "HTTPS_PROXY";
    # no_proxy = builtins.getEnv "no_proxy";
    # NO_PROXY = builtins.getEnv "NO_PROXY";

    # Explicit mentioning
    # http_proxy = "http://127.0.0.1:22222";
    # https_proxy = "http://127.0.0.1:22222";

  };
  # networking.proxy.default = builtins.getEnv "http_proxy";

}
