#!/usr/bin/env bash
# Re-source zathurarc in every open zathura (each owns org.pwmt.zathura.PID-<pid>).
for name in $(busctl --user list --no-legend | grep -oE '^org\.pwmt\.zathura\.PID-[0-9]+'); do
  gdbus call --session --dest "$name" --object-path /org/pwmt/zathura \
    --method org.pwmt.zathura.ExecuteCommand source >/dev/null
done
exit 0
