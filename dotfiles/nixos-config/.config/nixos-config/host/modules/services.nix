{ pkgs, username, ... }: {
  # Enable the X11 windowing system.
  services.xserver.enable = false;

  # Enable the GNOME Desktop Environment.
  # services.displayManager.gdm.enable = true;
  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "matrix";
      battery_id = "BAT0";
      bigclock = "en";
    };
  };
  services.desktopManager.gnome.enable = true;

  # Unlock the GNOME keyring with the login password when signing in through ly,
  # so apps that use the Secret Service (Claude Code, browsers, ...) don't prompt
  # for the keyring password on first use.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.ly.enableGnomeKeyring = true;

  services.gvfs.enable = true;

  # iPhone support: usbmuxd daemon handles pairing ("Trust This Computer"),
  # required for USB tethering (ipheth) and file access.
  services.usbmuxd.enable = true;
  environment.systemPackages = with pkgs; [
    libimobiledevice # idevicepair, ideviceinfo, ...
    ifuse # mount iPhone filesystem
  ];

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # GNOME
  services.gnome.gnome-online-accounts.enable = true;

  services.nordvpn.enable = true;
  users.users.${username}.extraGroups = [ "nordvpn" ];

}
