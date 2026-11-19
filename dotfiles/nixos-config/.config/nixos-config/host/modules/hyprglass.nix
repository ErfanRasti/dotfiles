# HyprGlass: Liquid Glass window/layer effect for Hyprland (https://github.com/hyprnux/hyprglass).
# Not in nixpkgs. Upstream pins one release per Hyprland commit (hyprpm.toml `commit_pins`);
# bump `rev`/`hash` together with Hyprland, using the pin listed for the new Hyprland commit.
{
  lib,
  fetchFromGitHub,
  mkHyprlandPlugin,
  wayland-scanner,
}:
mkHyprlandPlugin (finalAttrs: {
  pluginName = "hyprglass";
  version = "1.2.0"; # pinned for Hyprland 0.57.2 (11cbc6c)

  src = fetchFromGitHub {
    owner = "hyprnux";
    repo = "hyprglass";
    rev = "56714382e7ee6a46826bc8586f6d68b662c60c8a";
    hash = "sha256-yWfeuLNVhoLYDmrFrZ8YDoHSFObwvKoplwHvTulPWTs=";
  };

  # Per-surface blur scratch buffers instead of one shared buffer reallocated many times a second
  patches = [ ./hyprglass-blur-temp.patch ];

  nativeBuildInputs = [ wayland-scanner ];

  # No .git in the store source: give `hyprctl plugin list` the real version.
  makeFlags = [ "HYPRGLASS_VERSION=${finalAttrs.version}" ];

  installPhase = ''
    runHook preInstall
    install -Dm755 hyprglass.so $out/lib/libhyprglass.so
    runHook postInstall
  '';

  meta = {
    description = "Apple-style Liquid Glass effect for Hyprland";
    homepage = "https://github.com/hyprnux/hyprglass";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.linux;
  };
})
