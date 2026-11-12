# GNOME Circle apps (https://apps.gnome.org/#circle), read from the Circle team's own
# membership list (the `gnome-circle` flake input, data/apps.json), so the set follows
# Circle on every `nix flake update`.
#
# Each app comes from nixpkgs when `nixpkgsNames` maps its app ID to a package that is
# available, and from Flathub otherwise: new Circle apps show up as Flatpaks until they
# get an entry below, and a package nixpkgs drops or marks broken falls back to Flathub
# instead of breaking the build. Names are not guessed from the app ID because several
# would hit unrelated packages (`decoder`, `solanum`, `gnome-sudoku`).
{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  # App IDs to leave out entirely.
  exclude = [ ];

  nixpkgsNames = {
    "io.bassi.Amberol" = "amberol";
    "org.gnome.gitlab.somas.Apostrophe" = "apostrophe";
    "de.haeckerfelix.AudioSharing" = "audio-sharing";
    "com.belmoussaoui.Authenticator" = "authenticator";
    "io.github.kolunmi.Bazaar" = "bazaar";
    "app.drey.Biblioteca" = "biblioteca";
    "io.github.fizzyizzy05.binary" = "binary";
    "com.rafaelmardojai.Blanket" = "blanket";
    "com.feaneron.Boatswain" = "boatswain";
    "studio.planetpeanut.Bobby" = "bobby";
    "org.freedesktop.Bustle" = "bustle";
    "eu.fortysixandtwo.chessclock" = "chess-clock";
    "org.gnome.World.Citations" = "citations";
    "com.cassidyjames.clairvoyant" = "clairvoyant";
    "dev.geopjr.Collision" = "collision";
    "re.sonny.Commit" = "commit";
    "io.github.ronniedroid.concessio" = "concessio";
    "io.github.wartybix.Constrict" = "constrict";
    "com.github.huluti.Curtail" = "curtail";
    "org.gnome.DejaDup" = "deja-dup";
    "com.belmoussaoui.Decoder" = "gnome-decoder";
    "app.drey.Dialect" = "dialect";
    "io.github.revisto.drum-machine" = "drum-machine";
    "app.drey.EarTag" = "eartag";
    "app.drey.Elastic" = "elastic";
    "org.gnome.design.Emblem" = "emblem";
    "io.github.mrvladus.List" = "errands";
    "xyz.safeworlds.hiit" = "exercise-timer";
    "com.github.finefindus.eyedropper" = "eyedropper";
    "com.github.ADBeveridge.Raider" = "raider";
    "com.mardojai.ForgeSparks" = "forge-sparks";
    "de.haeckerfelix.Fragments" = "fragments";
    "dev.bragefuglseth.Fretboard" = "fretboard";
    "org.gaphor.Gaphor" = "gaphor";
    "be.alexandervanhee.gradia" = "gradia";
    "se.sjoerd.Graphs" = "gnome-graphs";
    "io.github.finefindus.Hieroglyphic" = "hieroglyphic";
    "org.gnome.gitlab.YaLTeR.Identity" = "identity";
    "io.gitlab.adhami3310.Impression" = "impression";
    "org.gnome.World.Iotas" = "iotas";
    "re.sonny.Junction" = "junction";
    "no.bragefuglseth.Keypunch" = "keypunch";
    "info.febvre.Komikku" = "komikku";
    "org.gnome.design.Lorem" = "lorem";
    "org.gnome.Mahjongg" = "gnome-mahjongg";
    "io.github.seadve.Mousai" = "mousai";
    "io.gitlab.news_flash.NewsFlash" = "newsflash";
    "com.belmoussaoui.Obfuscate" = "gnome-obfuscate";
    "io.github.diegoivan.pdf_metadata_editor" = "paper-clip";
    "org.gnome.World.PikaBackup" = "pika-backup";
    "org.gnome.Podcasts" = "gnome-podcasts";
    "org.gnome.Polari" = "polari";
    "de.schmidhuberj.DieBahn" = "diebahn";
    "net.nokyan.Resources" = "resources";
    "org.gnome.World.Secrets" = "gnome-secrets";
    "com.rafaelmardojai.SharePreview" = "share-preview";
    "de.haeckerfelix.Shortwave" = "shortwave";
    "org.gnome.Solanum" = "gnome-solanum";
    "io.gitlab.adhami3310.Converter" = "switcheroo";
    "re.sonny.Tangram" = "tangram";
    "io.gitlab.liferooter.TextPieces" = "textpieces";
    "dev.geopjr.Tuba" = "tuba";
    "io.github.idevecore.Valuta" = "valuta";
    "org.gnome.gitlab.YaLTeR.VideoTrimmer" = "video-trimmer";
    "app.drey.Warp" = "warp";
    "com.rafaelmardojai.WebfontKitGenerator" = "webfont-bundler";
    "com.github.hugolabe.Wike" = "wike";
    "dev.mufeed.Wordbook" = "wordbook";
    # Not in nixpkgs, from Flathub: Sessions, Sudoku, Tally, Workbench.
  };

  circleIds = lib.subtractLists exclude (
    map (app: app.app_id) (lib.importJSON "${inputs.gnome-circle}/data/apps.json")
  );

  # The package for an app ID, or null when it is unmapped, missing, renamed or unusable.
  nixpkg =
    id:
    let
      r = builtins.tryEval (
        let
          p = pkgs.${nixpkgsNames.${id}} or null; # tryEval misses missing attributes
        in
        if p != null && (p.meta.available or true) then p else null
      );
    in
    if nixpkgsNames ? ${id} && r.success then r.value else null;

  fromNixpkgs = lib.filter (id: nixpkg id != null) circleIds;
in
{
  home.packages = map nixpkg fromNixpkgs;
  services.flatpak.packages = lib.subtractLists fromNixpkgs circleIds;
}
