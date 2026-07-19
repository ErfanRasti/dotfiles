{ pkgs, lib, ... }:

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
  powerManagement.cpuFreqGovernor = "schedutil";

  services.thermald.enable = true;

  powerManagement.powertop.enable = true;
  systemd.services.powertop.serviceConfig.ExecStartPost = [ "${postPowertop}" ];

  services.upower.enable = true;

  services.logind.settings.Login.LidSwitch = "suspend";
  services.logind.settings.Login.PowerKey = "suspend";
  services.logind.settings.Login.PowerKeyLongPress = "poweroff";

  # PCIe Active State Power Management — lets PCIe devices enter low-power idle
  boot.kernelParams = [
    "pcie_aspm=force"
  ];

  # GPU power saving
  boot.extraModprobeConfig = ''
    options i915 enable_fbc=1 enable_psr=1 enable_dc=3
  '';

  services.power-profiles-daemon.enable = false;

  # services.auto-cpufreq.enable = true;
  # services.auto-cpufreq.settings = {
  #   battery = {
  #     governor = "powersave";
  #     turbo = "never";
  #   };
  #   charger = {
  #     governor = "balanced";
  #     turbo = "auto";
  #   };
  # };

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_SCALING_GOVERNOR_ON_AC = "balanced";

      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balanced";

      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 30;
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;

      TLP_DEFAULT_MODE = "BAT";
      TLP_PERSISTENT_DEFAULT = 1;
    };
  };

  # Power saving modes for hard disks
  services.udev.extraRules =
    let
      mkRule = as: lib.concatStringsSep ", " as;
      mkRules = rs: lib.concatStringsSep "\n" rs;
    in
    mkRules ([
      (mkRule [
        ''ACTION=="add|change"''
        ''SUBSYSTEM=="block"''
        ''KERNEL=="sd[a-z]"''
        ''ATTR{queue/rotational}=="1"''
        ''RUN+="${pkgs.hdparm}/bin/hdparm -B 90 -S 41 /dev/%k"''
      ])
    ]);
}
