{ stdenv
, testedPackage ? { }
}:

let
  executable = "rocm_agent_enumerator";
in stdenv.mkDerivation {
  pname = "${testedPackage.pname}-tests-${executable}";
  version = testedPackage.version;
  dontUnpack = true;
  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  doCheck = true;

  checkPhase = ''
    runHook preCheck
    ${testedPackage}/bin/${executable}
    ln -s ${testedPackage}/bin/${executable} $out
    runHook postCheck
  '';

  dontInstall = true;
  dontFixup = true;
  meta.maintainers = teams.rocm.members;
}
