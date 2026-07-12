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
}
