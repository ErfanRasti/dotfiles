{pkgs, ...}: {
  home.sessionVariables = {
    GTK_THEME = "adw-gtk3-dark"; # Replace with your theme's name
  };
  gtk = {
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
  };

  # noctalia shows application-x-executable (a gear in Papirus) for windows without an
  # app_id, such as Chrome's "... is sharing your screen." bar: make it Chrome's icon.
  xdg.dataFile."icons/Papirus".source = pkgs.runCommand "papirus-chrome-fallback" {} ''
    p=${pkgs.papirus-icon-theme}/share/icons/Papirus
    mkdir $out
    ln -s $p/index.theme $out/
    for f in $p/*/mimetypes/application-x-executable.svg; do
      d=$out/''${f#$p/}
      mkdir -p ''${d%/*}
      ln -s $p/64x64/apps/google-chrome.svg $d
    done
  '';
}
