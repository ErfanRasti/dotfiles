{ username, ... }: {
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # packages = with pkgs; [
    #   tree
    # ];
    initialPassword = "CHANGEME";
  };
}
