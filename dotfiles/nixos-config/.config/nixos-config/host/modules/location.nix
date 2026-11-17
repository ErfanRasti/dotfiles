{ pkgs, lib, username, ... }:
let
  # Python with GIO, for the agent; Gio.Settings reads the user's real dconf (not
  # GLib's memory fallback) only with dconf's GIO module, and finds the
  # org.gnome.system.location schema in gsettings-desktop-schemas.
  python = pkgs.python3.withPackages (ps: [ ps.pygobject3 ]);
  schemas = pkgs.gsettings-desktop-schemas;
  flag = "/run/browser-location/enabled"; # "1"/"0", written by the agent
  active = "/run/browser-location/active"; # "<epoch> <browser>" last locating, by root
  policyDirs = map (d: "${d}/policies/managed") [ "/etc/opt/chrome" "/etc/chromium" "/etc/opt/edge" ];
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
      BROWSER_LOCATION_FLAG = flag;
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

  # Chrome, Chromium and Edge skip GeoClue (their own Wi-Fi/IP lookup at Google; the
  # portal provider, LocationProviderManager:PlatformOnly, crashes Chrome 157), so the
  # switch reaches them as managed policy instead: off = DefaultGeolocationSetting 2
  # (blocked, over any site the user allowed), on = no policy (Chrome's own settings).
  # The agent can only write the flag; root writes the policy, so nothing running as
  # the user can set other browser policies. No flag (boot, before login) = blocked.
  # Chrome re-reads the policy folder a few seconds after it changes, but only if the
  # folder existed when it started, hence tmpfiles makes them at boot.
  systemd.tmpfiles.rules = [ "d ${dirOf flag} 0755 ${username} - -" ]
    ++ map (d: "d ${d} 0755 root root -") policyDirs;
  systemd.paths.browser-location-policy = {
    wantedBy = [ "paths.target" ];
    pathConfig.PathChanged = flag;
  };
  systemd.services.browser-location-policy = {
    description = "Browser location policy following GNOME's Location switch";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      on=$(cat ${flag} 2>/dev/null || :)
      for d in ${toString policyDirs}; do
        if [[ $on == 1 ]]; then
          rm -f "$d/location.json"
        else
          echo '{"DefaultGeolocationSetting": 2}' > "$d/location.json.tmp" && mv "$d/location.json.tmp" "$d/location.json"
        fi
      done
    '';
  };

  # Their lookups bypass GeoClue, so the bar's privacy widget can't see them there.
  # What they do have to do is ask NetworkManager for the Wi-Fi access points around;
  # this records when and which browser last did ("<epoch> <name>" in ${active}); the
  # widget (noctalia privacy plugin, probe.sh) shows it for a few seconds after.
  # Root because only root may monitor the system bus.
  systemd.services.browser-location-monitor = {
    description = "Note when a Chromium-based browser scans Wi-Fi to locate";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    path = [ pkgs.dbus pkgs.systemd ];
    serviceConfig.Restart = "always";
    script = ''
      dbus-monitor --system --monitor \
        "type='method_call',interface='org.freedesktop.NetworkManager.Device.Wireless'" |
      while read -r l; do
        [[ $l =~ sender=(:[0-9.]+) ]] || continue
        pid=$(busctl --system call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus \
          GetConnectionUnixProcessID s "''${BASH_REMATCH[1]}" 2>/dev/null) || continue
        case $(readlink "/proc/''${pid#u }/exe") in
          *google-chrome*) name="Google Chrome" ;;
          *chromium*) name=Chromium ;;
          *edge*) name="Microsoft Edge" ;;
          *) continue ;;
        esac
        echo "$EPOCHSECONDS $name" > ${active}.tmp && mv ${active}.tmp ${active}
      done
    '';
  };
}
