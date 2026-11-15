{ pkgs, lib, ... }:
let
  # Python with GIO, for the agent; Gio.Settings reads the user's real dconf (not
  # GLib's memory fallback) only with dconf's GIO module, and finds the
  # org.gnome.system.location schema in gsettings-desktop-schemas.
  python = pkgs.python3.withPackages (ps: [ ps.pygobject3 ]);
  schemas = pkgs.gsettings-desktop-schemas;
in
{
  # Location, through GeoClue (D-Bus activated; automatic-timezoned turns it on).
  #
  # GeoClue answers an app only once a GeoClue agent is registered for its user,
  # and asks the agent whether each app may locate. On GNOME that agent is
  # gnome-shell, which follows Settings > Privacy & Security > Location; the GNOME
  # module (services.nix) therefore turns GeoClue's demo agent off. But the session
  # is umbriel, not gnome-shell, so no agent ran: apps hung on GeoClue's GetClient
  # and fell back to their own lookups (Zen: Google's), and the Location switch did
  # nothing. location-agent.py stands in for gnome-shell: it follows the switch
  # ("Automatic Device Location") and its accuracy limit, live.
  services.geoclue2.enableDemoAgent = false; # the GNOME module's choice, kept: ours replaces it
  services.geoclue2.whitelistedAgents = [ "geoclue-gsettings-agent" ];

  systemd.user.services.geoclue-gsettings-agent = {
    description = "GeoClue agent following GNOME's Location settings";
    wantedBy = [ "default.target" ];
    unitConfig.ConditionUser = "!@system";
    environment = {
      GIO_EXTRA_MODULES = "${pkgs.dconf.lib}/lib/gio/modules";
      XDG_DATA_DIRS = "${schemas}/share/gsettings-schemas/${schemas.name}";
      GI_TYPELIB_PATH = lib.makeSearchPath "lib/girepository-1.0" [ pkgs.glib.out pkgs.gobject-introspection ];
    };
    serviceConfig = {
      Type = "exec";
      ExecStart = "${python}/bin/python3 -I -u ${./location-agent.py}";
      Restart = "on-failure";
    };
  };

  # The browsers go through the agent like any app (so the switch applies to them);
  # each site still needs the browser's own permission. DesktopId is the browser's
  # RemotingName: "zen" for Zen, "firefox" for Firefox (the module allows Firefox).
  services.geoclue2.appConfig.zen = { isAllowed = true; isSystem = false; };

  # GeoClue hides a client's DesktopId from everyone but the app holding it, so
  # noctalia's privacy widget names the app from GeoClue's debug log instead
  # ("'zen' started." / "'zen' stopped."). Only GeoClue's own domain, not GLib's.
  systemd.services.geoclue.environment.G_MESSAGES_DEBUG = "Geoclue GeoClue geoclue";
}
