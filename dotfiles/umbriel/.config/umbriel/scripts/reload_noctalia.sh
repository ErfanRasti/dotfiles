#!/usr/bin/env bash
# Restart noctalia (also re-registers its polkit agent).

# noctalia ships its own polkit agent, so stop the GNOME one first.
systemctl --user stop polkit-gnome.service 2>/dev/null
# The process shows up as ".noctalia-wrapped" on NixOS; wait for it to exit, since
# its single-instance lock makes a new one quit otherwise.
pkill -f '^noctalia( |$)' && timeout 3 pidwait -f '^noctalia( |$)'
# The agent is registered for $XDG_SESSION_ID; callers outside a session scope (kitty and
# other systemd-launched apps) resolve to logind's Display session, so use that.
s=$(loginctl show-user "$USER" -p Display --value 2>/dev/null)
XDG_SESSION_ID=${s:-$XDG_SESSION_ID} setsid -f noctalia >/dev/null 2>&1
