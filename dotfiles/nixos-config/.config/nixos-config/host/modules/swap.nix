{ lib, ... }:

{

  # Check the results using: swapon --show

  # `zram` configuration
  # https://search.nixos.org/options?query=zramSwap

  #swapDevices = lib.mkForce [ ];
  # boot.kernelParams = [ "systemd.swap=0" ];
  # zramSwap = {
  #   enable = true;
  #   memoryPercent = 50; # zram-size = min(ram / 2, 4096)
  #   memoryMax = 4 * 1024 * 1024 * 1024; # Cap at 4 GB
  #   algorithm = "zstd";
  #   priority = 40;
  # };

  # `zswap` configuration
  # https://search.nixos.org/options?channel=unstable&query=boot.zswap
  # https://www.reddit.com/r/archlinux/comments/1ivwv1l/zram_vs_zswap_vs_swap/
  boot.zswap = {
    enable = true;
    compressor = "zstd";
    maxPoolPercent = 20;
    shrinkerEnabled = true;
  };

  # Swap partition
  # https://wiki.nixos.org/wiki/Swap
  # After changing this to take effect: `sudo systemctl restart var-lib-swapfile.swap`
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 32 * 1024; # 32 GB
      priority = 20;
    }
  ];

  # Hibernation is supported by default no need to do something.
  # https://nixos.wiki/wiki/Hibernation
}
