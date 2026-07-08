{
  imports = [
    ./packages.nix # Home packages, programs, unfree
    ./themes.nix # Themes settings
    ./desktop-entries.nix # Desktop entries
  ];
  # nix.settings = {
  #   http-proxy = builtins.getEnv "http_proxy"; # or hardcode it
  #   https-proxy = builtins.getEnv "https_proxy"; # or hardcode it
  #   # Or use the networking module (better for NixOS):
  #   # networking.proxy.default = "http://proxy:port/";
  #   # networking.proxy.noProxy = "127.0.0.1,localhost,...";
  # };
}
