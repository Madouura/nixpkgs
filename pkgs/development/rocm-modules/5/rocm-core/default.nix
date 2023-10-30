{ lib
, stdenv
, fetchFromGitHub
, commonNativeBuildInputs
, commonCMakeFlags
, rocmUpdateScript
, rocmPackages_5
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rocm-core";
  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-core";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-jFAHLqf/AR27Nbuq8aypWiKqApNcTgG5LWESVjVCKIg=";
  };

  nativeBuildInputs = commonNativeBuildInputs;

  cmakeFlags = [
    (lib.cmakeFeature "ROCM_VERSION" finalAttrs.version)
    (lib.cmakeFeature "CPACK_PACKAGING_INSTALL_PREFIX" (placeholder "out"))
  ] ++ commonCMakeFlags;

  passthru.updateScript = rocmUpdateScript {
    name = finalAttrs.pname;
    owner = finalAttrs.src.owner;
    repo = finalAttrs.src.repo;
    page = "tags?per_page=1";
    filter = ".[0].name | split(\"-\") | .[1]";
  };

  meta = with lib; {
    description = "Utility for getting the ROCm release version";
    homepage = "https://github.com/RadeonOpenCompute/rocm-core";
    license = with licenses; [ mit ];
    maintainers = teams.rocm.members;
    platforms = platforms.linux;
    broken = versions.minor finalAttrs.version != versions.minor rocmPackages_5.llvm.llvm.version;
  };
})
