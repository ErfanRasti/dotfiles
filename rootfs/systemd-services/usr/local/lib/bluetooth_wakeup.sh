#!/bin/bash
# Auto-detect Bluetooth USB devices and enable system wakeup using bluetooth device

log() { echo "[usb-bt-wakeup] $*"; }

for prod in /sys/bus/usb/devices/*/product; do
  dev="${prod%/product}"
  [[ "$dev" == *:* ]] && continue

  product=$(cat "$prod" 2>/dev/null)
  [[ "$product" != *[Bb]luetooth* ]] && continue

  wakeup="$dev/power/wakeup"
  if [ -w "$wakeup" ]; then
    echo 'enabled' >"$wakeup"
    log "Enabled wakeup for $product"
  fi
done
