"""Nautilus setup from inside its process, following matugen live.

- Icons: Adwaita-Matugen (made by ~/.config/matugen/scripts/folder_icons.py), for Nautilus
  only; switching it away and back on changes makes GTK and Nautilus redraw their icons.
- Colors: GTK 4 reads ~/.config/gtk-4.0/gtk.css only at startup, so reload it on changes.
- Folders: FOLDER_ICONS sets folder icons; Nautilus ignores them in the sidebar, so the
  sidebar rows of those folders get the icons' symbolic versions here.
- Bookmarks: made from ~/.config/gtk-3.0/bookmarks-template on the first run.
"""

import os
import subprocess

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
from gi.repository import Gdk, Gio, GLib, GObject, Gtk, Nautilus  # noqa: E402

ICON_THEME = "Adwaita-Matugen"
ICONS = os.path.join(GLib.get_user_data_dir(), "icons", ICON_THEME)
CSS = os.path.join(GLib.get_user_config_dir(), "gtk-4.0", "gtk.css")
GTK3 = os.path.join(GLib.get_user_config_dir(), "gtk-3.0")
FOLDER_ICONS = {"Desktop": "user-desktop", "programs": "folder-programs"}  # under $HOME


def descendants(widget):
    child = widget.get_first_child()
    while child:
        yield child
        yield from descendants(child)
        child = child.get_next_sibling()


class NautilusTheme(GObject.GObject, Nautilus.MenuProvider):
    def __init__(self):
        super().__init__()
        display = Gdk.Display.get_default()
        self._settings = Gtk.Settings.get_for_display(display)
        if os.path.isdir(ICONS):  # made on matugen's first run
            self._settings.props.gtk_icon_theme_name = ICON_THEME
        self._css = Gtk.CssProvider()
        Gtk.StyleContext.add_provider_for_display(
            display, self._css, Gtk.STYLE_PROVIDER_PRIORITY_USER + 1)
        self._pending = 0
        self._watched = []  # monitors and list models, kept alive
        for path in (os.path.dirname(CSS), os.path.join(ICONS, "scalable")):
            self._watch(Gio.File.new_for_path(path).monitor_directory(Gio.FileMonitorFlags.NONE),
                        "changed", self._on_changed)

        self._sidebar_icons = {}
        for name, icon in FOLDER_ICONS.items():
            folder = Gio.File.new_for_path(os.path.join(GLib.get_home_dir(), name))
            if folder.query_exists():
                folder.set_attribute_string("metadata::custom-icon-name", icon, 0)
                self._sidebar_icons[folder.get_uri()] = Gio.ThemedIcon.new(f"{icon}-symbolic")
        self._sidebars = set()
        self._watch(Gtk.Window.get_toplevels(), "items-changed",
                    lambda *_: GLib.idle_add(self._scan_windows))  # once their widgets exist

        if not os.path.exists(os.path.join(GTK3, "bookmarks")):
            subprocess.run([os.path.join(GTK3, "scripts", "generate_bookmarks.sh"),
                            os.path.join(GTK3, "bookmarks-template")], check=False)

    def _watch(self, obj, signal, callback):
        obj.connect(signal, callback)
        self._watched.append(obj)

    def _on_changed(self, *_):  # matugen writes many files in a row: wait for the last
        if self._pending:
            GLib.source_remove(self._pending)
        self._pending = GLib.timeout_add(300, self._reload)

    def _reload(self):
        self._pending = 0
        if os.path.isfile(CSS):
            self._css.load_from_path(CSS)
        if os.path.isdir(ICONS):
            self._settings.props.gtk_icon_theme_name = "hicolor"
            self._settings.props.gtk_icon_theme_name = ICON_THEME
        return GLib.SOURCE_REMOVE

    def _scan_windows(self):  # watch each window's sidebar for (re)built rows
        for window in Gtk.Window.get_toplevels():
            for sidebar in descendants(window):
                if type(sidebar).__name__ == "NautilusSidebar" and sidebar not in self._sidebars:
                    self._sidebars.add(sidebar)
                    for widget in descendants(sidebar):
                        if isinstance(widget, Gtk.ListBox):
                            self._watch(widget.observe_children(), "items-changed",
                                        lambda rows, *_: self._fix_rows(rows))
                            self._fix_rows(widget.observe_children())
        return GLib.SOURCE_REMOVE

    def _fix_rows(self, rows):
        for row in rows:
            if type(row).__name__ == "NautilusSidebarRow":
                icon = self._sidebar_icons.get(row.props.uri)
                if icon and not (row.props.start_icon and icon.equal(row.props.start_icon)):
                    row.props.start_icon = icon
