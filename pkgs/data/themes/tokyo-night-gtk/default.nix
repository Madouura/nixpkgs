{ lib
, stdenvNoCC
, fetchFromGitHub
, makeScopeWithSplicing'
, generateSplicesForMkScope
, unstableGitUpdater
, gtk-engine-murrine
, gnome-themes-extra
}:

# Why do we do this? This package has a LOT of files! The user may not need
# some of these themes and icons and the ~100k extra files in them.
# We also need to use `makeScopeWithSplicing'` to get around cross problems.
# https://github.com/NixOS/nixpkgs/issues/211340
let
  icons = {
    dark = base.override { tkIcon = "Dark"; tkTheme = ""; };
    dark-cyan = base.override { tkIcon = "Dark-Cyan"; tkTheme = ""; };
    light = base.override { tkIcon = "Light"; tkTheme = ""; };
    moon = base.override { tkIcon = "Moon"; tkTheme = ""; };
  };

  themes = {
    dark-b = base.override { tkIcon = ""; tkTheme = "Dark-B"; };
    dark-bl = base.override { tkIcon = ""; tkTheme = "Dark-BL"; };
    dark-b-lb = base.override { tkIcon = ""; tkTheme = "Dark-B-LB"; };
    dark-bl-lb = base.override { tkIcon = ""; tkTheme = "Dark-BL-LB"; };
    storm-b = base.override { tkIcon = ""; tkTheme = "Storm-B"; };
    storm-bl = base.override { tkIcon = ""; tkTheme = "Storm-BL"; };
    storm-b-lb = base.override { tkIcon = ""; tkTheme = "Storm-B-LB"; };
    storm-bl-lb = base.override { tkIcon = ""; tkTheme = "Storm-BL-LB"; };
  };

  base = {
    tkIcon ? ""
  , tkTheme ? ""
  }: stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "tokyo-night-gtk" + (
      if tkIcon != ""
      then lib.toLower "-icons-${tkIcon}"
      else ""
    ) + (
      if tkTheme != ""
      then lib.toLower "-themes-${tkTheme}"
      else ""
    );

    version = "unstable-2023-05-30";

    outputs = [
      "out"
    ] ++ lib.optionals (tkIcon == "" && tkTheme == "") [
      "icon"
      "theme"
    ];

    src = fetchFromGitHub {
      owner = "Fausto-Korpsvart";
      repo = "Tokyo-Night-GTK-Theme";
      rev = "e9790345a6231cd6001f1356d578883fac52233a";
      hash = "sha256-Q9UnvmX+GpvqSmTwdjU4hsEsYhA887wPqs5pyqbIhmc=";
    };

    propagatedUserEnvPkgs = [
      gtk-engine-murrine
      gnome-themes-extra
    ];

    dontPatch = true;
    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;

    installPhase = let
      allIcons = with icons; [ dark dark-cyan light moon ];
      allThemes = with themes; [ dark-b dark-bl dark-b-lb dark-bl-lb storm-b storm-bl storm-b-lb storm-bl-lb ];
    in ''
      runHook preInstall
    '' + lib.optionalString (tkIcon == "" && tkTheme == "") ''
      mkdir -p {$icon,$theme}/share/{icons,themes}
      ${lib.concatMapStrings (x: "ln -s ${x}/share/icons/* $icon/share/icons\n") allIcons}
      ${lib.concatMapStrings (x: "ln -s ${x}/share/themes/* $theme/share/themes\n") allThemes}
      mkdir -p $out/share
      ln -s $icon/share/icons $out/share
      ln -s $theme/share/themes $out/share
    '' + lib.optionalString (tkIcon != "") ''
      mkdir -p $out/share/icons
      cp -a icons/Tokyonight-${tkIcon} $out/share/icons
    '' + lib.optionalString (tkTheme != "") ''
      mkdir -p $out/share/themes
      cp -a themes/Tokyonight-${tkTheme} $out/share/themes
    '' + ''
      runHook postInstall
    '';

    passthru = {
      inherit icons themes;
      updateScript = unstableGitUpdater { };
    };

    meta = with lib; {
      description = "A GTK theme based on the Tokyo Night colour palette";
      homepage = "https://www.pling.com/p/1681315";
      license = licenses.gpl3Only;
      platforms = platforms.unix;
      maintainers = with maintainers; [ garaiza-93 ];
    };
  });
in makeScopeWithSplicing' {
  otherSplices = generateSplicesForMkScope "tokyo-night-gtk";
  f = tokyoNightFun;
}
