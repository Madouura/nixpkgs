{ lib
, fetchFromGitHub
, rocmMkDerivation ? { }
, ...
}:

{ }:

rocmMkDerivation { } (finalAttrs: oldAttrs: {
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

  passthru.prefixName = "hip-common";

  meta = with lib; oldAttrs.meta // {
    description = "C++ Heterogeneous-Compute Interface for Portability";
    homepage = "https://github.com/ROCm-Developer-Tools/HIP";
    license = with licenses; [ mit ];
    maintainers = with maintainers; oldAttrs.meta.maintainers ++ [ lovesegfault ];
  };
})
