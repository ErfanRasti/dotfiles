# MATLAB's runtime libraries: nix-matlab's list (common.nix), for the matlab overlay
# (home.nix) and COMSOL's LiveLink (comsol.nix).
#
# common.nix still uses `pkgs.xorg.*`, which nixpkgs deprecated: every access prints
# an evaluation warning. Hand it a `xorg` set made of the new top-level names instead,
# so new libraries upstream adds are still picked up, without the warnings.
# gtk2 is dropped: nixpkgs marks it broken and R2024a doesn't link it.
inputs: pkgs:
let
  xorg = {
    libSM = pkgs.libsm;
    libX11 = pkgs.libx11;
    libxcb = pkgs.libxcb;
    libXcomposite = pkgs.libxcomposite;
    libXcursor = pkgs.libxcursor;
    libXdamage = pkgs.libxdamage;
    libXext = pkgs.libxext;
    libXfixes = pkgs.libxfixes;
    libXft = pkgs.libxft;
    libXi = pkgs.libxi;
    libXinerama = pkgs.libxinerama;
    libXrandr = pkgs.libxrandr;
    libXrender = pkgs.libxrender;
    libXt = pkgs.libxt;
    libXtst = pkgs.libxtst;
    libXxf86vm = pkgs.libxxf86vm;
    libICE = pkgs.libice;
  };
in
builtins.filter (p: (p.pname or "") != "gtk+") (
  import "${inputs.nix-matlab}/common.nix" (pkgs // { inherit xorg; })
)
