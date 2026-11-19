{
  pkgs,
  config,
  lib,
  ...
}:
# Hyprland plugins, built by Nix against the exact Hyprland this system runs.
#
# Replaces hyprpm: hyprpm compiles plugins at runtime against downloaded headers, which
# go stale on every Hyprland update ("headers outdated" / version mismatch) and need a
# compiler toolchain on PATH. Here the plugins come from the binary cache and are rebuilt
# in lockstep with programs.hyprland.package on every `nixos-rebuild switch`.
#
# They are linked to /etc/hypr/plugins/<name>.so; ~/.config/hypr/config/plugins.lua loads
# whatever is there. Add or remove a plugin here and rebuild; no Hyprland config change needed.
let
  hyprlandPlugins = pkgs.hyprlandPlugins.override {
    hyprland = config.programs.hyprland.package;
  };

  # Hyprspace with an optional vertical (niri/umbriel-style) overview, see the patch header
  hyprspace = hyprlandPlugins.hyprspace.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./hyprspace-vertical.patch ];
  });

  hyprglass = pkgs.callPackage ./hyprglass.nix {
    inherit (hyprlandPlugins) mkHyprlandPlugin;
  };

  plugins = [
    hyprlandPlugins.hyprbars # title bars (SUPER+B toggles them)
    hyprglass # liquid glass windows/layers (packaged here, see hyprglass.nix)
    hyprspace # workspace overview (SUPER+O), vertical like niri/umbriel
    # Removed: hyprfocus (the focus glow + dim_inactive cover it), hy3 (the built-in
    # layouts cover it), hypr-dynamic-cursors (does not build on Hyprland 0.57)
  ];
in
{
  environment.etc = lib.listToAttrs (
    map (p: {
      name = "hypr/plugins/${p.pname}.so";
      value.source = "${p}/lib/lib${p.pname}.so";
    }) plugins
  );
}
