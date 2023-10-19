{ lib
, stdenvNoCC
, fetchFromGitHub
, unstableGitUpdater
, gtk-engine-murrine
, gnome-themes-extra
}:

let
  pnameNoMod = "tokyo-night-gtk";
  pnameIconsMod = "${pnameNoMod}-icons";
  pnameThemesMod = "${pnameNoMod}-themes";
in stdenvNoCC.mkDerivation (finalAttrs: {
  pname = pnameNoMod;
  version = "unstable-2023-05-30";

  outputs = [
    "out"
  ] ++ lib.optionals (
    (!lib.hasPrefix pnameIconsMod finalAttrs.pname) &&
    (!lib.hasPrefix pnameThemesMod finalAttrs.pname)
  ) [
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
    allIcons = with finalAttrs.passthru.icons; [ dark dark-cyan light moon ];
    allThemes = with finalAttrs.passthru.themes; [ dark-b dark-bl dark-b-lb dark-bl-lb storm-b storm-bl storm-b-lb storm-bl-lb ];
  in ''
    runHook preInstall
  '' + lib.optionalString (finalAttrs.pname == pnameNoMod) ''
    mkdir -p {$icon,$theme}/share/{icons,themes}
    ${lib.concatMapStrings (x: "ln -s ${x}/share/icons/* $icon/share/icons\n") allIcons}
    ${lib.concatMapStrings (x: "ln -s ${x}/share/themes/* $theme/share/themes\n") allThemes}
    mkdir -p $out/share
    ln -s $icon/share/icons $out/share
    ln -s $theme/share/themes $out/share
  '' + lib.optionalString (lib.hasPrefix pnameIconsMod finalAttrs.pname) ''
    mkdir -p $out/share/icons
    cp -a icons/Tokyonight${lib.removePrefix pnameIconsMod finalAttrs.pname} $out/share/icons
  '' + lib.optionalString (lib.hasPrefix pnameThemesMod finalAttrs.pname) ''
    mkdir -p $out/share/themes
    cp -a themes/Tokyonight${lib.removePrefix pnameThemesMod finalAttrs.pname} $out/share/themes
  '' + ''
    runHook postInstall
  '';

  passthru = let
    base = finalAttrs.finalPackage;
  in {
    # We shouldn't have to worry about cross compiling for these sub-derivations
    # So why do we do this? This package has a LOT of files! The user may not need
    # some of these themes and icons and the ~100k extra files in them.
    icons = {
      dark = base.overrideAttrs { pname = "${pnameIconsMod}-Dark"; };
      dark-cyan = base.overrideAttrs { pname = "${pnameIconsMod}-Dark-Cyan"; };
      light = base.overrideAttrs { pname = "${pnameIconsMod}-Light"; };
      moon = base.overrideAttrs { pname = "${pnameIconsMod}-Moon"; };
    };

    themes = {
      dark-b = base.overrideAttrs { pname = "${pnameThemesMod}-Dark-B"; };
      dark-bl = base.overrideAttrs { pname = "${pnameThemesMod}-Dark-BL"; };
      dark-b-lb = base.overrideAttrs { pname = "${pnameThemesMod}-Dark-B-LB"; };
      dark-bl-lb = base.overrideAttrs { pname = "${pnameThemesMod}-Dark-BL-LB"; };
      storm-b = base.overrideAttrs { pname = "${pnameThemesMod}-Storm-B"; };
      storm-bl = base.overrideAttrs { pname = "${pnameThemesMod}-Storm-BL"; };
      storm-b-lb = base.overrideAttrs { pname = "${pnameThemesMod}-Storm-B-LB"; };
      storm-bl-lb = base.overrideAttrs { pname = "${pnameThemesMod}-Storm-BL-LB"; };
    };

    updateScript = unstableGitUpdater { };
  };

  meta = with lib; {
    description = "A GTK theme based on the Tokyo Night colour palette";
    homepage = "https://www.pling.com/p/1681315";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
    maintainers = with maintainers; [ garaiza-93 ];
  };
})
