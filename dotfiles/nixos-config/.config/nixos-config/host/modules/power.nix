{ pkgs, ... }:
let
  postPowertop = pkgs.writeShellScript "post-powertop" ''
    log() { echo "[usb-bt-wakeup] $*"; }

    # Don't suspend plugged-in USB input devices
    for f in $(find /sys/bus/usb/drivers/usbhid -regex '.*\/[0-9:.-]+' -printf '%f\n' | cut -d ":" -f 1 | sort -u); do
      echo on >|"/sys/bus/usb/devices/$f/power/control"
    done

    # Auto-detect Bluetooth USB devices and enable system wakeup
    for prod in /sys/bus/usb/devices/*/product; do
      dev=''${prod%/product}
      [[ "$dev" == *:* ]] && continue

      product=$(cat "$prod" 2>/dev/null)
      [[ "$product" != *[Bb]luetooth* ]] && continue

      wakeup="$dev/power/wakeup"
      if [ -w "$wakeup" ]; then
        echo 'enabled' >"$wakeup"
        log "Enabled wakeup for $product"
      fi
    done
  '';
in
{
  powerManagement.enable = true;
  services.thermald.enable = true;
  services.power-profiles-daemon.enable = true;
  powerManagement.powertop.enable = true;

  systemd.services.powertop.serviceConfig.ExecStartPost = [ "${postPowertop}" ];

  services.logind.settings.Login.LidSwitch = "suspend";
  services.logind.settings.Login.PowerKey = "suspend";
  services.logind.settings.Login.PowerKeyLongPress = "poweroff";
}
