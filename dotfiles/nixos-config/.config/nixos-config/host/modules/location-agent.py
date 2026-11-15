"""A GeoClue agent that follows GNOME's location settings, as gnome-shell does.

GeoClue serves an app only once an agent is registered for its user, and asks
that agent (AuthorizeApp) whether each app may locate, and how precisely. On
GNOME, gnome-shell is the agent and honours Settings > Privacy & Security >
Location; under umbriel nothing did. This agent:

  - answers AuthorizeApp from org.gnome.system.location: refused while
    "Automatic Device Location" (enabled) is off, else allowed up to
    max-accuracy-level
  - publishes MaxAccuracyLevel (0 while off) and signals its changes, so GeoClue
    cuts off apps already locating as soon as the switch goes off
  - registers with GeoClue (Manager.AddAgent) each time GeoClue appears on the
    bus; GeoClue is D-Bus activated and idles out, and this never starts it

The agent's id must be in geoclue.conf's [agent] whitelist (location.nix).
Part of the dotfiles, under the repo's GPL-3.0 license (LICENSE at the repo root).
"""

from gi.repository import Gio, GLib

AGENT_ID = "geoclue-gsettings-agent"
GC = "org.freedesktop.GeoClue2"
AGENT_PATH = "/org/freedesktop/GeoClue2/Agent"

# GClueAccuracyLevel, by GNOME's max-accuracy-level names.
LEVELS = {"country": 1, "city": 4, "neighborhood": 5, "street": 6, "exact": 8}

XML = """
<node>
  <interface name="org.freedesktop.GeoClue2.Agent">
    <method name="AuthorizeApp">
      <arg name="desktop_id" type="s" direction="in"/>
      <arg name="req_accuracy_level" type="u" direction="in"/>
      <arg name="authorized" type="b" direction="out"/>
      <arg name="allowed_accuracy_level" type="u" direction="out"/>
    </method>
    <property name="MaxAccuracyLevel" type="u" access="read"/>
  </interface>
</node>
"""

settings = Gio.Settings.new("org.gnome.system.location")
bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)


def max_level():
    if not settings.get_boolean("enabled"):
        return 0
    return LEVELS.get(settings.get_string("max-accuracy-level"), 8)


def log(msg):
    print(msg, flush=True)


# GDBus answers calls to undeclared methods and properties itself, so these serve
# only AuthorizeApp and MaxAccuracyLevel.
def on_call(conn, sender, path, iface, method, params, invocation):
    desktop_id, wanted = params.unpack()
    allowed = min(wanted, max_level())
    log(f"{desktop_id}: {'allowed' if allowed else 'refused'} (asked {wanted}, gave {allowed})")
    invocation.return_value(GLib.Variant("(bu)", (allowed > 0, allowed)))


def on_get_property(conn, sender, path, iface, prop):
    return GLib.Variant("u", max_level())


def on_settings_changed(_settings, _key):
    level = max_level()
    log(f"location settings changed: max accuracy {level}")
    bus.emit_signal(
        None,
        AGENT_PATH,
        "org.freedesktop.DBus.Properties",
        "PropertiesChanged",
        GLib.Variant(
            "(sa{sv}as)",
            ("org.freedesktop.GeoClue2.Agent", {"MaxAccuracyLevel": GLib.Variant("u", level)}, []),
        ),
    )


def on_registered(conn, result):
    try:
        conn.call_finish(result)
        log(f"registered with GeoClue as {AGENT_ID}")
    except GLib.Error as e:
        log(f"GeoClue refused the agent: {e.message}")


def on_geoclue_appeared(conn, name, owner):
    conn.call(
        GC, "/org/freedesktop/GeoClue2/Manager", f"{GC}.Manager", "AddAgent",
        GLib.Variant("(s)", (AGENT_ID,)), None, Gio.DBusCallFlags.NO_AUTO_START, -1, None,
        on_registered,
    )


def main():
    node = Gio.DBusNodeInfo.new_for_xml(XML)
    bus.register_object(AGENT_PATH, node.interfaces[0], on_call, on_get_property, None)
    settings.connect("changed::enabled", on_settings_changed)
    settings.connect("changed::max-accuracy-level", on_settings_changed)
    Gio.bus_watch_name_on_connection(bus, GC, Gio.BusNameWatcherFlags.NONE, on_geoclue_appeared, None)
    log(f"location agent up; max accuracy {max_level()}")
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
