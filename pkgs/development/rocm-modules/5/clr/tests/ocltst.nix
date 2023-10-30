{ stdenv
, testedPackage ? { }
}:

let
  executable = "ocltst";
in stdenv.mkDerivation {
  pname = "${testedPackage.pname}-tests-${executable}";
  version = testedPackage.version;
  dontUnpack = true;
  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    ln -s ${testedPackage}/share/opencl/ocltst/${executable} $out
    runHook postInstall
  '';

  dontFixup = true;

  meta = with lib; {
    maintainers = teams.rocm.members;
    # Needs to be ran in `impureTests`
    broken = true;
  };
}
