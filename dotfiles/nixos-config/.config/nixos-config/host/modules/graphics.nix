{
  pkgs,
  config,
  lib,
  ...
}:
{
  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [
    "modesetting" # example for Intel iGPU; use "amdgpu" here instead if your iGPU is AMD
    "nvidia"
  ];

  # Intel Graphics
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # Required for modern Intel GPUs (Xe iGPU and ARC)
      intel-media-driver # VA-API (iHD) userspace
      vpl-gpu-rt # oneVPL (QSV) runtime
      intel-vaapi-driver # For older processors. LIBVA_DRIVER_NAME=i965

      # Optional (compute / tooling):
      intel-compute-runtime # OpenCL (NEO) + Level Zero for Arc/Xe
      # NOTE: 'intel-ocl' also exists as a legacy package; not recommended for Arc/Xe.
      # libvdpau-va-gl       # Only if you must run VDPAU-only apps
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD"; # Prefer the modern iHD backend
    # VDPAU_DRIVER = "va_gl";      # Only if using libvdpau-va-gl
  };

  # May help if FFmpeg/VAAPI/QSV init fails (esp. on Arc with i915):
  hardware.enableRedistributableFirmware = true;
  boot.kernelParams = [ "i915.enable_guc=3" ];

  # May help services that have trouble accessing /dev/dri (e.g., jellyfin/plex):
  # users.users.<service>.extraGroups = [ "video" "render" ];

  # Nvidia Graphics
  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = true;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # inherit nvidiaBusId intelBusId;

      # Auto-detect Intel iGPU bus ID
      # 8086 = Intel Corporation
      intelBusId =
        let
          intelPci = builtins.readFile (
            pkgs.runCommand "intel-bus-id" { } ''
              ${pkgs.pciutils}/bin/lspci -d 8086: | ${pkgs.gnugrep}/bin/grep -iE "3D|VGA|Display" | head -1 | cut -d' ' -f1 > $out
            ''
          );
        in
        "PCI:${lib.replaceStrings [ "." ] [ ":" ] (lib.trim intelPci)}";

      # Auto-detect NVIDIA bus ID
      # 10de = NVIDIA Corporation
      nvidiaBusId =
        let
          nvidiaPci = builtins.readFile (
            pkgs.runCommand "nvidia-bus-id" { } ''
              ${pkgs.pciutils}/bin/lspci -d 10de: | ${pkgs.gnugrep}/bin/grep -iE "3D|VGA" | head -1 | cut -d' ' -f1 > $out
            ''
          );
        in
        "PCI:${lib.replaceStrings [ "." ] [ ":" ] (lib.trim nvidiaPci)}";

    };
  };

  # warnings =
  #   let
  #     inherit (config.hardware.nvidia.prime) nvidiaBusId intelBusId;
  #   in
  #   [
  #     "Using NVIDIA bus ID: ${nvidiaBusId}"
  #     "Using Intel iGPU bus ID: ${intelBusId}"
  #     "To use different bus IDs, set nvidiaBusId and intelBusId parameters"
  #     "Find your bus IDs by running: lspci | grep -E 'VGA|3D'"
  #   ];

  system.activationScripts.nvidia-bus-ids =
    let
      inherit (config.hardware.nvidia.prime) nvidiaBusId intelBusId;
    in
    ''
      echo "INFO: NVIDIA bus ID: ${nvidiaBusId}"
      echo "INFO: Intel iGPU bus ID: ${intelBusId}"
      echo "INFO: To use different bus IDs, set nvidiaBusId and intelBusId parameters"
      echo "INFO: Find your bus IDs by running: lspci | grep -E 'VGA|3D'"
    '';

}
