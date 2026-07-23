{ lib, ... }:

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
}
