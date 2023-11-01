{ lib
, fetchFromGitHub
, rocmPackages
}:

(finalAttrs: oldAttrs: {
  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-core";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-jFAHLqf/AR27Nbuq8aypWiKqApNcTgG5LWESVjVCKIg=";
  };

  nativeBuildInputs = rocmPackages.util.commonNativeBuildInputs;

  cmakeFlags = [
    (lib.cmakeFeature "ROCM_VERSION" finalAttrs.version)
    (lib.cmakeFeature "CPACK_PACKAGING_INSTALL_PREFIX" (placeholder "out"))
  ] ++ rocmPackages.util.commonCMakeFlags;

  passthru = oldAttrs.passthru // {
    prefixName = "rocm-core";

    updateScript = rocmPackages.util.rocmUpdateScript {
      name = finalAttrs.passthru.prefixName;
      owner = finalAttrs.src.owner;
      repo = finalAttrs.src.repo;
      page = "tags?per_page=1";
      filter = ".[0].name | split(\"-\") | .[1]";
    };
  };

  meta = with lib; oldAttrs.meta // {
    description = "Utility for getting the ROCm release version";
    homepage = "https://github.com/RadeonOpenCompute/rocm-core";
    license = with licenses; [ mit ];
    platforms = platforms.unix;
  };
})
