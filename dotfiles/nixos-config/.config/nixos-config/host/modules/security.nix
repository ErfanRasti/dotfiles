{ config, pkgs, ... }:
let
  # Face scan in the background, unlocking through logind on a match (Noctalia listens
  # to logind's Unlock). It returns at once, so the password field stays usable while
  # the camera works. Only scans while the session is locked, at most 3 tries, one
  # instance at a time. Started by the lockscreen's `login` PAM stack on a failed or
  # empty password, and by swayidle after resume.
  howdyBackgroundUnlock = pkgs.writeShellScriptBin "howdy-background-unlock" ''
    user="''${PAM_USER:-$(${pkgs.coreutils}/bin/id -un)}"
    uid=$(${pkgs.coreutils}/bin/id -u "$user" 2>/dev/null) || exit 0
    [ "$(${pkgs.coreutils}/bin/id -u)" = "$uid" ] || exit 0 # only for your own session
    session=$(${pkgs.systemd}/bin/loginctl show-user "$user" -p Display --value 2>/dev/null)
    [ -n "$session" ] || exit 0
    ${pkgs.util-linux}/bin/setsid -f ${pkgs.bash}/bin/bash -c '
      exec 9>"$1"; ${pkgs.util-linux}/bin/flock -n 9 || exit 0
      for _ in 1 2 3; do
        [ "$(${pkgs.systemd}/bin/loginctl show-session "$2" -p LockedHint --value)" = yes ] || exit 0
        # workaround = "native" makes pam_howdy ask for a password alongside the scan;
        # an input that stays open but empty keeps that prompt waiting (a closed one
        # makes howdy give up before the camera starts).
        if ${pkgs.pamtester}/bin/pamtester howdy-unlock "$3" authenticate < <(${pkgs.coreutils}/bin/sleep 10); then
          ${pkgs.systemd}/bin/loginctl unlock-session "$2"
          exit 0
        fi
      done
    ' _ "/run/user/$uid/howdy-background-unlock.lock" "$session" "$user" </dev/null >/dev/null 2>&1
    exit 0
  '';
in
{
  # sudo visudo
  security.sudo.extraConfig = ''
    Defaults env_keep += "http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ftp_proxy no_proxy"
  '';

  # `oomd`
  # https://search.nixos.org/options?channel=unstable&query=systemd.oomd
  # systemd.oomd = {
  #   enable = true;
  #   enableUserSlices = true; # protects system, manages user processes
  #   # enableSystemSlice = false;    # default, fine to leave
  #   # enableRootSlice = false;      # default, fine to leave
  #   settings.OOM = {
  #     SwapUsedLimitPercent = 80; # act when 80% swap is used
  #     MemoryUsedLimitPercent = 80; # act when 80% RAM is used
  #   };
  # };

  # `earlyoom`
  # https://search.nixos.org/options?channel=unstable&query=services.earlyoom
  services.earlyoom = {
    enable = true;

    # Thresholds (in % of free memory/swap)
    # These are quite aggressive (good for desktops) — adjust based on your RAM amount
    freeMemThreshold = 20; # Send SIGTERM when free RAM drops below 10%
    freeSwapThreshold = 20; # ...and free swap also below 10%

    # Harder kill thresholds (SIGKILL)
    freeMemKillThreshold = 10; # Force kill with SIGKILL below 5% free RAM
    freeSwapKillThreshold = 10; # Force kill with SIGKILL below 5% free swap

    # Extra command-line arguments (most important for desktop UX)
    extraArgs = [
      # "-g"                          # Kill entire process group (recommended for browsers/Electron)

      # Protect critical desktop processes (never kill these)
      "--avoid"
      "^(X|plasma.*|kwin|kde.*|gnome.*|Hyprland|sway|waybar|dbus|systemd|init|Xorg|ssh|pipewire|pulseaudio|wireplumber)$"

      # Prefer killing heavy memory hogs (common culprits)
      # "--prefer"
      # "^(electron|firefox|zen|chromium|brave|libreoffice|gimp|inkscape|discord|steam|qemu|virt-manager)$"
    ];

    # Optional but recommended
    enableNotifications = true; # Show desktop notification when something is killed
    enableDebugInfo = false; # Set to true only when troubleshooting
    reportInterval = 3600; # Print memory report to journal every 3600s (0 = disable)
  };

  # `apparmor`
  # https://search.nixos.org/options?channel=unstable&query=apparmor
  services.dbus.apparmor = "enabled";
  security.apparmor = {
    enable = true; # Activate AppArmor MAC; requires reboot after initial enable

    enableCache = false; # Whether to enable caching of AppArmor policies in `/var/cache/apparmor/`.
    # Disable cache: profile contents contain Nix store paths,
    # so cached versions accumulate rapidly on each rebuild

    # Kill processes that violate AppArmor profile instead of just logging
    # This enforces strict security rather than permissive mode
    killUnconfinedConfinables = true;

    # Apply AppArmor profiles to all packages installed in the system closure
    # Automatically loads profiles from /nix/store for every package
    packages = [ pkgs.apparmor-profiles ];

  };

  # Enable AppArmor confinement for systemd services by default
  # Any service without a profile will be blocked from starting
  systemd.services."*".serviceConfig.AppArmorProfile = true;

  # Enable sshd using
  # services.openssh = {
  #   enable = true;
  #   openFirewall = true;
  # };

  # polkit status
  security.polkit.enable = true;

  # howdy
  security.pam.howdy.enable = true;
  services.howdy = {
    enable = true;
    settings = {
      core = {
        # no_confirmation = true;
        # pam_howdy only asks for the password *alongside* the face scan when this is not
        # "off" (the NixOS default). "native" cancels the pending prompt on a face match;
        # "input" would fake an Enter via /dev/uinput, which the sandboxed polkit helper
        # can't reach.
        workaround = "native";
      };
    };
  };
  services.howdy.control = "sufficient";

  # Noctalia's lockscreen authenticates through the `login` service. With howdy in that
  # stack, a correct password waited for the camera, and a face scan blocked the
  # password field. Instead: the password is checked alone, and when it fails (Enter on
  # an empty field included) pam_exec starts the background face scan above and
  # returns at once, so you can type the password while the camera works.
  security.pam.services.login = {
    howdy.enable = false;
    rules.auth.howdy-background = {
      order = config.security.pam.services.login.rules.auth.unix.order + 10;
      control = "optional";
      modulePath = "${pkgs.linux-pam}/lib/security/pam_exec.so";
      args = [
        "quiet"
        "${howdyBackgroundUnlock}/bin/howdy-background-unlock"
      ];
    };
  };

  # Face-only service the background scan authenticates against.
  security.pam.services.howdy-unlock = {
    howdy.enable = true;
    unixAuth = false;
  };
  # On PATH so swayidle can start a scan after resume (umbriel/scripts/swayidle_runner.sh).
  environment.systemPackages = [ howdyBackgroundUnlock ];

  # polkit >= 127 runs the PAM stack for pkexec/polkit agents (Noctalia) in a sandboxed,
  # socket-activated `polkit-agent-helper@` unit with PrivateDevices + DevicePolicy=strict,
  # so howdy can't open the camera there ("not possible to open camera at configured path")
  # and the request fails before the password prompt. Let that unit reach the camera.
  systemd.services."polkit-agent-helper@".serviceConfig = {
    PrivateDevices = false;
    DeviceAllow = [ "char-video4linux rw" ];
    MemoryDenyWriteExecute = false; # howdy's python/dlib/opencv
  };
  # services.linux-enable-ir-emitter.enable = true;
}
