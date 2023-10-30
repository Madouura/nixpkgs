{ stdenv
, testedPackage ? { }
}:

let
  executable = "rdctst";
in stdenv.mkDerivation {
  pname = "${testedPackage.pname}-tests-${executable}";
  version = testedPackage.version;
  dontUnpack = true;
  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    ln -s ${testedPackage}/share/rdc/rdctst_tests/${executable} $out
    runHook postInstall
  '';

  dontFixup = true;

  meta = with lib; {
    maintainers = teams.rocm.members;
    # Needs to be ran in `impureTests`
    broken = true;
  };
}
