#!/usr/bin/env bash
# noctalia registers its polkit agent only at startup; restart it whenever polkitd
# (re)appears on the bus (e.g. `nixos-rebuild switch`), else pkexec falls back to a tty prompt.
# NameOwnerChanged args: name, old, new; a non-empty new owner means polkitd started.
dbus-monitor --system "type='signal',sender='org.freedesktop.DBus',member='NameOwnerChanged',arg0='org.freedesktop.PolicyKit1'" |
  awk '/member=NameOwnerChanged/ { n = 0; next }
       /^ *string "/ && ++n == 3 && $2 != "\"\"" { system("sleep 1; exec ~/.config/umbriel/scripts/reload_noctalia.sh") }'
