{ pkgs, ... }:
{
  # GNOME Settings ships with OnlyShowIn=GNOME, so shells running under other
  # desktops (umbriel/noctalia) drop the entry and fall back to fuzzy token
  # matching, which resolves org.gnome.Settings to nvidia-settings' icon.
  # Derive the entry from the installed package, minus the OnlyShowIn filter.
  xdg.dataFile."applications/org.gnome.Settings.desktop".source =
    pkgs.runCommand "org.gnome.Settings.desktop" { } ''
      sed -e '/^OnlyShowIn=/d' \
        -e 's|^Exec=gnome-control-center|Exec=env XDG_CURRENT_DESKTOP=GNOME gnome-control-center|' \
        ${pkgs.gnome-control-center}/share/applications/org.gnome.Settings.desktop > $out
    '';

  xdg.desktopEntries.google-chrome = {
    name = "Google Chrome";
    genericName = "Web Browser";
    comment = "Access the Internet";
    exec = "google-chrome --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=TouchpadOverscrollHistoryNavigation %U";
    startupNotify = true;
    terminal = false;
    icon = "google-chrome";
    type = "Application";
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = [
      "application/pdf"
      "application/rdf+xml"
      "application/rss+xml"
      "application/xhtml+xml"
      "application/xhtml_xml"
      "application/xml"
      "image/gif"
      "image/jpeg"
      "image/png"
      "image/webp"
      "text/html"
      "text/xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];

    actions = {
      "new-window" = {
        name = "New Window";
        exec = "google-chrome --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=TouchpadOverscrollHistoryNavigation";
      };

      "new-private-window" = {
        name = "New Incognito Window";
        exec = "google-chrome --incognito --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=TouchpadOverscrollHistoryNavigation";
      };
    };
  };

  xdg.desktopEntries.microsoft-edge = {
    name = "Microsoft Edge";
    genericName = "Web Browser";
    comment = "Access the Internet";
    exec = "microsoft-edge --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=TouchpadOverscrollHistoryNavigation %U";
    startupNotify = true;
    terminal = false;
    icon = "microsoft-edge";
    type = "Application";
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = [
      "application/pdf"
      "application/rdf+xml"
      "application/rss+xml"
      "application/xhtml+xml"
      "application/xhtml_xml"
      "application/xml"
      "image/gif"
      "image/jpeg"
      "image/png"
      "image/webp"
      "text/html"
      "text/xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];

    actions = {
      "new-window" = {
        name = "New Window";
        exec = "microsoft-edge --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=TouchpadOverscrollHistoryNavigation";
      };

      "new-private-window" = {
        name = "New InPrivate Window";
        exec = "microsoft-edge --inprivate --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=TouchpadOverscrollHistoryNavigation";
      };
    };
  };
  xdg.desktopEntries.code = {
    name = "Visual Studio Code";
    comment = "Code Editing. Redefined.";
    genericName = "Text Editor";
    exec = "code --enable-features=UseOzonePlatform --ozone-platform=wayland %F";
    icon = "visual-studio-code";
    type = "Application";
    startupNotify = false;
    categories = [
      "TextEditor"
      "Development"
      "IDE"
    ];
    mimeType = [ "application/x-code-workspace" ];

    actions = {
      "new-empty-window" = {
        name = "New Empty Window";
        exec = "code --new-window --enable-features=UseOzonePlatform --ozone-platform=wayland %F";
        icon = "visual-studio-code";
      };
    };
  };
  xdg.desktopEntries.whatsapp = {
    name = "WhatsApp";
    exec = "chromium --app=https://web.whatsapp.com";
    icon = "whatsapp";
    categories = [
      "Network"
      "Chat"
    ];
  };
}
