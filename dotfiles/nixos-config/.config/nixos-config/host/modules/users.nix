{ username, ... }: {
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
    ];
    # packages = with pkgs; [
    #   tree
    # ];
    initialPassword = "CHANGEME";
  };
}
