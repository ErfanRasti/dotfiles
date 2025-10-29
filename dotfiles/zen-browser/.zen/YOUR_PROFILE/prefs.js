// user.js — shareable prefs from your Zen Browser profile
// Place in your profile folder; apply on next start.

// ==============================
// Recommended extensions to install (manually)
// (IDs here are public add-on IDs, NOT your UUID mappings.)
// - addon@darkreader.org               // Dark Reader
// - jid1-<ID>@jetpack                  // DuckDuckGo Privacy Essentials
// - button@scholar.google.com          // Google Scholar Button
// -                                    // MYNT: Material You New Tab
// - pywalfox@frewacom.org              // Pywalfox
// - extension@tabliss.io               // Tabliss
// -                                    // Varia Integrator
// - <ID>                               // ChatGPT to PDF by PDFCrowd
// - <ID>                               // enhanced-h264ify
// - <ID>@jetpack                       // Grammarly for Firefox
// - webapps@mendeley.com               // Mendeley Web Importer
// - tridactyl.vim@cmcaine.co.uk        // Tridactyl
// - firefox-webext@zenmate.com         // ZenMate
// - screenshots@mozilla.org            // Firefox Screenshots (built-in)
// - giantpinkrobots@protonmail.com     // Proton Mail (legacy/webext id)
// (People should install the ones they want; these lines are just a checklist.)
// AMO = addons.mozilla.org
// ==============================

// ============ Privacy / network ============
user_pref("browser.contentblocking.category", "strict");
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("privacy.trackingprotection.emailtracking.enabled", true);
user_pref("privacy.query_stripping.enabled", true);
user_pref("privacy.query_stripping.enabled.pbmode", true);
user_pref("privacy.bounceTrackingProtection.mode", 1);
user_pref("privacy.fingerprintingProtection", true);
user_pref(
  "network.http.referer.disallowCrossSiteRelaxingDefault.top_navigation",
  true
);
// Keep this; it’s a public DoH resolver endpoint (not unique to you).
user_pref(
  "network.trr.custom_uri",
  "https://mozilla.cloudflare-dns.com/dns-query"
);
// Reduce data upload telemetry (generic)
user_pref("datareporting.usage.uploadEnabled", false);

// ============ Core UI ============
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.toolbars.bookmarks.visibility", "always");
user_pref("browser.urlbar.placeholderName", "Google");
user_pref("browser.search.suggest.enabled", true);
user_pref("accessibility.typeaheadfind", true);
user_pref("accessibility.typeaheadfind.flashBar", 0);
user_pref("general.autoScroll", true);
user_pref("ui.key.menuAccessKeyFocuses", false);
user_pref("pdfjs.enableAltText", true);
user_pref("pdfjs.enableAltTextForEnglish", true);
user_pref(
  "extensions.pictureinpicture.enable_picture_in_picture_overrides",
  true
);

// ============ Tabs / chrome ============
user_pref("browser.tabs.groups.enabled", true);
user_pref("browser.tabs.groups.arc-style", false);
user_pref("browser.tabs.allow_transparent_browser", true);
user_pref("browser.tabs.inTitlebar", 1);

// ============ Zen behavior & layout ============
user_pref("zen.urlbar.behavior", "float");
user_pref("zen.urlbar.replace-newtab", false);
user_pref("zen.view.compact.hide-toolbar", true);
user_pref("zen.view.use-deprecated-urlbar", true);
user_pref("zen.view.use-single-toolbar", false);
user_pref("zen.splitView.change-on-hover", true);
user_pref("zen.workspaces.continue-where-left-off", true);
user_pref("zen.themes.disable-all", false);
user_pref("zen.theme.accent-color", "#f6b0ea");
user_pref("zen.view.compact.enable-at-startup", false);
user_pref("zen.view.compact.should-enable-at-startup", false);

// ============ Arc-style visuals ============
user_pref("arc-menu-icon", true);
user_pref("arc-tab-loading-animation", 1);
user_pref("arc-tab-switch-animation", 1);
user_pref("arc-urlbar-animation", 1);
user_pref("arc-workspace-style", 0);
user_pref("arc-compact-sidebar-size", "25em");
user_pref("arc-enable-container-styling", 1);
user_pref("arc-font", "Nunito");
user_pref("arc-marginless-mod", 0);
user_pref("arc.compact.sidebar-blur", "30px");
user_pref("arc.compact.sidebar-opacity", "0.3");
user_pref("arc.next-page-animation", true);
user_pref("arc.previous-page-animation", true);
user_pref("arc.urlbar.opacity", 0);
user_pref("arcline.url.bar", 0);

// ============ Floaty mod (fuller set) ============
user_pref("mod.floaty.use-transparency", true);
user_pref("mod.floaty.transparency-value", "0.72");
user_pref("mod.floaty.use-blur", true);
user_pref("mod.floaty.blur-radius", "32px");
user_pref("mod.floaty.blur-saturation", "128%");
user_pref("mod.floaty.use-animation", true);
user_pref("mod.floaty.animation-duration", "0.15s");
user_pref("mod.floaty.margin", "8px");
user_pref("mod.floaty.findbar-top-margin", "64px");
user_pref("mod.floaty.findbar-max-width", "1060px");
user_pref("mod.floaty.use-floating-topbar", true);
user_pref("mod.floaty.use-floating-sidebar", true);
user_pref("mod.floaty.use-floating-findbar", true);
user_pref("mod.floaty.use-themed-topbar", true);
user_pref("mod.floaty.use-themed-sidebar", true);
user_pref("mod.floaty.use-themed-findbar", true);
user_pref("mod.floaty.use-themed-urlbar", true);

// ============ Forked Tidy Popup ============
user_pref("mod.forkedtidypopup.flatstyletoolbar", true);
user_pref("mod.forkedtidypopup.keepdividers", true);
user_pref("mod.forkedtidypopup.usecenterbookmarkbar", true);
user_pref("mod.forkedtidypopup.usecustomhovercolor", true);
user_pref("mod.forkedtidypopup.hovercolor.dark", "rgba(87,65,50,255)");
user_pref("mod.forkedtidypopup.hovercolor.light", "rgba(243,202,176,255)");
user_pref("mod.forkedtidypopup.usetidyextension", true);
user_pref("mod.forkedtidypopup.usetidypopup", true);
user_pref("mod.forkedtidypopup.usezenprimarycolor", true);

// ============ SameeraSW Zen cosmetics ============
user_pref("mod.sameerasw.zen_bg_color_enabled", false);
user_pref("mod.sameerasw.zen_compact_sidebar_width", "180px");
user_pref("mod.sameerasw.zen_no_shadow", false);
user_pref("mod.sameerasw.zen_notab_img_enabled", true);
user_pref(
  "mod.sameerasw.zen_notab_img",
  "url('https://github.com/sameerasw/my-internet/blob/main/wave-light.png?raw=true')"
);
user_pref("mod.sameerasw.zen_notab_img_size", "150px");
user_pref("mod.sameerasw.zen_notab_img_invert", true);
user_pref("mod.sameerasw.zen_notab_img_opacity", "1");
user_pref("mod.sameerasw.zen_transparency_color", "#fff222");
user_pref("mod.sameerasw.zen_transparent_glance_enabled", true);
user_pref("mod.sameerasw.zen_transparent_sidebar_enabled", true);
user_pref("mod.sameerasw.zen_urlbar_zoom_anim", true);
user_pref("mod.sameerasw.zen_tab_switch_anim", true);
user_pref("mod.sameerasw.zen_trackpad_anim", true);
user_pref("mod.sameerasw_zen_animations", "0");
user_pref("mod.sameerasw_zen_compact_sidebar_type", "0");
user_pref("mod.sameerasw_zen_light_tint", "2");

// ============ Nebula theme variables ============
user_pref("nebula-active-tab-glow", 2);
user_pref("nebula-default-sound-style", 2);
user_pref("nebula-essentials-gray-icons", true);
user_pref("nebula-folder-styling", false);
user_pref("nebula-glow-gradient", 1);
user_pref("nebula-macos-style-buttons", false);
user_pref("nebula-nogaps-mod", true);
user_pref("nebula-pinned-extensions-mod", false);
user_pref("nebula-remove-workspace-indicator", false);
user_pref("nebula-tab-loading-animation", 0);
user_pref("nebula-tab-switch-animation", 0);
user_pref("nebula-tabs-no-shadow", false);
user_pref("nebula-turn-off-zen-menu-icon", true);
user_pref("nebula-urlbar-animation", 1);
user_pref("nebula-workspace-style", 0);
user_pref("var-nebula-border-radius", "14px");
user_pref("var-nebula-color-glass-dark", "rgba(0, 0, 0, 0.4)");
user_pref("var-nebula-color-glass-light", "rgba(255, 255, 255, 0.4)");
user_pref("var-nebula-color-shadow-dark", "rgba(0, 0, 0, 0.55)");
user_pref("var-nebula-color-shadow-light", "rgba(255, 255, 255, 0.55)");
user_pref("var-nebula-essentials-width", "60px");
user_pref("var-nebula-glass-blur", "100px");
user_pref("var-nebula-glass-saturation", "150%");
user_pref("var-nebula-tabs-default-dark", "rgba(0,0,0,0.35)");
user_pref("var-nebula-tabs-default-light", "rgba(255,255,255,0.25)");
user_pref("var-nebula-tabs-hover-dark", "rgba(0,0,0,0.45)");
user_pref("var-nebula-tabs-hover-light", "rgba(255,255,255,0.35)");
user_pref("var-nebula-tabs-minimum-dark", "rgba(0, 0, 0, 0.1)");
user_pref("var-nebula-tabs-minimum-light", "rgba(255, 255, 255, 0.1)");
user_pref("var-nebula-tabs-selected-dark", "rgba(0,0,0,0.45)");
user_pref("var-nebula-tabs-selected-light", "rgba(255,255,255,0.45)");
user_pref("var-nebula-ui-tint-dark", "rgba(0,0,0,0.5)");
user_pref("var-nebula-ui-tint-light", "rgba(255,255,255,0.5)");
user_pref("var-nebula-website-tint-dark", "rgba(0,0,0,0.3)");
user_pref("var-nebula-website-tint-light", "rgba(255,255,255,0.3)");

// ============ PSU (Ctrl+Tab + titles) ============
user_pref("psu.better_ctrltab.width", "85vw");
user_pref("psu.better_ctrltab.zoom", "0.8");
user_pref("psu.better_ctrltab.padding", "16px");
user_pref("psu.better_ctrltab.roundness", "28px");
user_pref("psu.better_ctrltab.shadow_size", "18px");
user_pref("psu.better_ctrltab.preview_font_size", "13px");
user_pref("psu.better_ctrltab.preview_favicon_size", "18px");
user_pref("psu.better_ctrltab.preview_favicon_outdent", "12px");
user_pref("psu.better_ctrltab.preview_border_width", "1px");
user_pref(
  "psu.better_ctrltab.preview_border_color",
  "light-dark(rgba(255, 255, 255, 0.1), rgba(1, 1, 1, 0.1))"
);
user_pref(
  "psu.better_ctrltab.preview_focus_background",
  "light-dark(rgba(77, 77, 77, 0.8), rgba(204, 204, 204, 0.33))"
);
user_pref(
  "psu.better_ctrltab.preview_focus_border_color",
  "light-dark(rgba(255, 255, 255, 0.1), rgba(1, 1, 1, 0.1))"
);
user_pref("psu.better_ctrltab.preview_letter_spacing", "0px");
user_pref("psu.tab_title_fixes.font_size", "13px");
user_pref("psu.tab_title_fixes.pending_opacity", "0.55");

// ============ Misc visuals ============
user_pref("btrnewtab.border-radius", "8px");
user_pref("btrtabs.border-radius", "8px");
user_pref("tab-shadow-enabled", true);
user_pref("border-shadow-disabled", true);
user_pref("widget.gtk.overlay-scrollbars.enabled", false);

// ============ Theme ============
user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org"); // public theme id

// ============ Power user (only if you use userChromeJS) ============
user_pref("userChromeJS.enabled", true);
user_pref("userChromeJS.allowUnsafeWrites", true);
user_pref("userChromeJS.firstRunShown", true);
user_pref("userChromeJS.persistent_domcontent_callback", true);
user_pref("userChromeJS.scriptsDisabled", "");
