#!/usr/bin/env bash
# On resume the laptop panel reconnects while locked, and noctalia (5.4.1-5.5.0) leaves
# its lockscreen widgets off the new lock surface; a config reload re-attaches them.
# Retried in case the panel comes back late. Run first by swayidle's after-resume.
for delay in 0.5 1 2; do
  sleep "$delay"
  [[ "$(noctalia msg status 2>/dev/null)" == *'"locked": true'* ]] || exit 0
  noctalia msg config-reload >/dev/null
done
