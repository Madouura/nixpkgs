{ lib
, stdenv
, fetchFromGitHub
, rocmUpdateScript
, rocmPackages_5
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "hip-common";
  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "HIP";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-1Abit9qZCwrCVcnaFT4uMygFB9G6ovRasLmTsOsJ/Fw=";
  };

  postPatch = ''
    patchShebangs tests docs bin
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    cp -a . $out
    runHook postInstall
  '';

  passthru.updateScript = rocmUpdateScript {
    name = finalAttrs.pname;
    owner = finalAttrs.src.owner;
    repo = finalAttrs.src.repo;
  };

  meta = with lib; {
    description = "C++ Heterogeneous-Compute Interface for Portability";
    homepage = "https://github.com/ROCm-Developer-Tools/HIP";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ lovesegfault ] ++ teams.rocm.members;
    platforms = platforms.linux;
    broken = versions.minor finalAttrs.version != versions.minor rocmPackages_5.llvm.llvm.version;
  };
})
