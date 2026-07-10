{ username, ... }: {
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "video"
    ];
    # packages = with pkgs; [
    #   tree
    # ];
    initialPassword = "CHANGEME";
  };
}
