{
  pkgs,
  config,
  inputs,
  ...
}:
{

  nixpkgs.config.allowUnfree = true;
  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).

  # Enable Wayland compositors for display manager session entries
  programs.hyprland.enable = true;
  programs.niri.enable = true;

  environment.systemPackages = with pkgs; [
    # System management
    pciutils
    usbutils
    config.hardware.nvidia.package.bin
    home-manager

    # Terminal tools
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    neovim
    tmux
    wget
    sbctl
    wl-clipboard # for waydroid copy and paste
    wl-clip-persist # Keep Wayland clipboard even after programs close

  ];

  # To check the current nix-ld modules: l /run/current-system/sw/share/nix-ld/lib/
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      ## Put here any library that is required when running a package
      # libraries to run conda
      stdenv.cc.cc
      zlib
      openssl
      curl
      glib
      libx11
      libxrender
      libice
      libsm

      ## Uncomment if you want to use the libraries provided by default in the steam distribution
      ## but this is quite far from being exhaustive
      ## https://github.com/NixOS/nixpkgs/issues/354513
      # (pkgs.runCommand "steamrun-lib" {} "mkdir $out; ln -s ${pkgs.steam-run.fhsenv}/usr/lib64 $out/lib")
    ];
  };
  ## Uncomment if you used steamrun's libraries
  # nixpkgs.config.allowUnfree = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  services.hardware.openrgb.enable = true;

  # Waydroid
  virtualisation.waydroid.enable = true;
  # Newer kernel versions may need
  # virtualisation.waydroid.package = pkgs.waydroid-nftables;

  environment.pathsToLink = [ "share/thumbnailers" ];

  programs.gpu-screen-recorder = {
    package = inputs.gsr-ui-nix.packages.${pkgs.stdenv.hostPlatform.system}.gpu-screen-recorder;
    enable = true;
    ui.enable = true;
  };

  programs.throne = {
    enable = true;
    tunMode.enable = true;
  };
}
