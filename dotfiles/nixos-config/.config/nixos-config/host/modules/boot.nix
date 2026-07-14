{ lib, ... }: {
  # Use the systemd-boot EFI boot loader.
  # boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.extraModprobeConfig = ''
    options rtl8723be ant_sel=2 ips=0 fwlps=0
  '';

  # https://wiki.nixos.org/wiki/Plymouth
  boot.plymouth = {
    enable = true;
  };

  # Enable "Silent boot"
  boot = {
    consoleLogLevel = 3; # only kernel messages with log level ≥3 (KERN_ERR and above) appear on the console.
    initrd.verbose = false; # suppresses verbose output from the initial ramdisk (initrd) phase.
    kernelParams = [
      "quiet" # reduces kernel log verbosity (equivalent to loglevel=3).
      "rd.udev.log_level=3" # limits udev (device manager) messages in the initrd to errors only.
      "rd.systemd.show_status=auto" # shows systemd status in initrd only on slow/broken consoles (suppresses the usual boot splash output).
      "rd.systemd.device_timeout=5" # reduce device probe timeout from 90s to 5s
    ];
    blacklistedKernelModules = [
      "serial8250" # no serial ports on this laptop, saves ~30s of device probing
      "iTCO_wdt" # Intel watchdog not needed
      "xe" # redundant with i915 on Tiger Lake, saves ~4.5 MB slab
      "ahci" # no SATA drives (both are NVMe), saves ~0.5 MB slab
    ];
  };

  # Hide the OS choice for bootloaders.
  # It's still possible to open the bootloader list by pressing any key
  # It will just not appear on screen unless a key is pressed
  # boot.loader.timeout = 0;
  boot.loader.timeout = 4;

  # boot.kernelParams = [ "psmouse.synaptics_intertouch=0" ];

  # Secure Boot
  # See https://nix-community.github.io/lanzaboote/getting-started/prepare-your-system.html
  # Lanzaboote currently replaces the systemd-boot module.
  # This setting is usually set to true in configuration.nix
  # generated at installation time. So we force it to false
  # for now.
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
}
