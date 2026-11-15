{ lib, pkgs, ... }:

{
  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Disable onboard Bluetooth (Intel 9460/9560 Jefferson Peak)
  # USB Vendor ID: 8087 (Intel Corp.)
  # USB Product ID: 0x0AAA
  # Identify with: lsusb | grep "Intel Corp. Bluetooth"
  services.udev.extraRules = lib.concatStringsSep "\n" [
    ''SUBSYSTEM=="usb", ATTR{idVendor}=="8087", ATTR{idProduct}=="0aaa", ATTR{authorized}="0"''
  ];

  # Bluetooth firmware for TP-LINK Bluetooth dongle (RTL8761B/BU)
  # Same old firmware as the AUR rtl8761b-firmware package; newer builds
  # from linux-firmware drop idle mice. hiPrio makes it win over linux-firmware.
  hardware.firmware = [
    (lib.hiPrio (
      pkgs.stdenvNoCC.mkDerivation {
        pname = "rtl8761b-firmware-old";
        version = "162105963";
        src = pkgs.fetchFromGitHub {
          owner = "andrew-ld";
          repo = "rtl8761b-firmware";
          rev = "4b36bce18a5c9162d0c4f63ff70abcc5e9db9e28";
          hash = "sha256-5DB7eGmKmnn2PQUHjDmKRPiNPZjC3pkSbEiE7rjdJOI=";
        };
        installPhase = ''
          install -Dm644 -t $out/lib/firmware/rtl_bt rtl8761b{,u}_{fw,config}.bin
        '';
      }
    ))
  ];

}
