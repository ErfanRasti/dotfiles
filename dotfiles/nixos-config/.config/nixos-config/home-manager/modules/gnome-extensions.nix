{ pkgs, ... }: {

  home.packages = with pkgs.gnomeExtensions; [
    airpod-battery-monitor
    app-grid-wizard
    appindicator
    app-menu-is-back
    applications-menu
    gsconnect
    hibernate-status-button
    lock-keys-2
    open-desktop-file-location
    places-status-indicator
    tiling-shell
    window-gestures
    auto-adwaita-colors
    battery-health-charging
    battery-time-2
    blocker
    bluetooth-battery-meter
    blur-my-shell
    burn-my-windows
    clipboard-history
    copyous
    dash-to-dock
    emoji-copy
    gpu-profile-selector
    gtk4-desktop-icons-ng-ding
    just-perfection
    kando-integration
    open-bar
    persian-calendar-2
    rounded-window-corners-reborn
    tray-icons-reloaded
    user-themes
    uxplay-control
    vitals
    weather-oclock
    windownavigator
    dynamic-music-pill
  ];

  dconf = {
    enable = true;
    settings = {

      # dconf/GSettings key path that holds GNOME Shell's settings
      # (same one the GNOME Shell Extensions app writes to).
      "org/gnome/shell" = {

        # do not disable user extensions" — i.e. allow extensions to load.
        # If set to true, GNOME Shell ignores enabled-extensions entirely and won't load any user extension.
        disable-user-extensions = false;

        enabled-extensions = with pkgs.gnomeExtensions; [
          airpod-battery-monitor.extensionUuid
          app-grid-wizard.extensionUuid
          appindicator.extensionUuid
          app-menu-is-back.extensionUuid
          applications-menu.extensionUuid
          gsconnect.extensionUuid
          hibernate-status-button.extensionUuid
          lock-keys-2.extensionUuid
          open-desktop-file-location.extensionUuid
          places-status-indicator.extensionUuid
          tiling-shell.extensionUuid
          window-gestures.extensionUuid
          dynamic-music-pill.extensionUuid
          dash-to-dock.extensionUuid
        ];
      };
    };
  };
}
