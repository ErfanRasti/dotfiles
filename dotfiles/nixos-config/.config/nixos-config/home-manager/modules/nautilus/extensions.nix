# Nautilus extensions missing from nixpkgs, built from flake inputs of the same name that
# follow upstream (see flake.nix).
{
  lib,
  stdenv,
  stdenvNoCC,
  inputs,
  autoreconfHook,
  meson,
  ninja,
  pkg-config,
  gettext,
  glib,
  gtk4,
  nautilus,
  imagemagick,
}:
let
  source = name: {
    pname = name;
    version = "0-unstable-${builtins.substring 0 8 inputs.${name}.lastModifiedDate}";
    src = inputs.${name};
  };

  python =
    name: installPhase:
    stdenvNoCC.mkDerivation (
      source name
      // {
        inherit installPhase;
        dontBuild = true; # actions-for-nautilus' Makefile would install into ~/.local
      }
    );

  compiled =
    name: buildTool: postPatch:
    stdenv.mkDerivation (
      source name
      // {
        inherit postPatch;
        nativeBuildInputs = buildTool ++ [
          pkg-config
          gettext
        ];
        buildInputs = [
          glib
          gtk4
          nautilus
        ];
        # pkg-config reports Nautilus' own store path as the extension dir
        env.PKG_CONFIG_LIBNAUTILUS_EXTENSION_4_EXTENSIONDIR = "${placeholder "out"}/lib/nautilus/extensions-4";
      }
    );
in
{
  # Context-menu entries from ~/.local/share/actions-for-nautilus/config.json
  actions-for-nautilus = python "actions-for-nautilus" ''
    mkdir -p $out/share/nautilus-python
    cp -r extensions $out/share/nautilus-python
  '';

  # "Open as admin" / "Edit as admin" (gvfs admin://, asks the polkit agent)
  nautilus-admin = python "nautilus-admin-gtk4" ''
    install -Dm644 extension/nautilus-admin.py -t $out/share/nautilus-python/extensions
    substituteInPlace $out/share/nautilus-python/extensions/nautilus-admin.py \
      --replace-fail @NAUTILUS_PATH@ nautilus
  '';

  # Checksums tab in the properties window
  nautilus-checksums = compiled "nautilus-checksums" [ autoreconfHook ] "";

  # Resize / rotate images
  nautilus-image-converter =
    compiled "nautilus-image-converter"
      [
        meson
        ninja
      ]
      ''
        substituteInPlace src/nautilus-image-{resizer,rotator}.c \
          --replace-fail /usr/bin/convert ${lib.getExe' imagemagick "convert"}
        # fr.po declares an empty charset, which msgfmt rejects (no-op once upstream fixes it)
        substituteInPlace po/fr.po --replace-quiet 'charset=\n' 'charset=UTF-8\n'
      '';

  # "Sharing Options" for folders (Samba's `net usershare`, needs host Samba)
  nautilus-share = compiled "nautilus-share" [
    meson
    ninja
  ] "";
}
