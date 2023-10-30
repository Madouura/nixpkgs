{ lib
, stdenv
, fetchFromGitHub
, commonNativeBuildInputs
, commonCMakeFlags
, rocmUpdateScript
, rocmPackages_5
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "clang-ocl";
  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "clang-ocl";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-uMSvcVJj+me2E+7FsXZ4l4hTcK6uKEegXpkHGcuist0=";
  };

  nativeBuildInputs = commonNativeBuildInputs;
  buildInputs = with rocmPackages_5; [ rocm-device-libs ];
  cmakeFlags = commonCMakeFlags;
  doCheck = true;

  passthru.updateScript = rocmUpdateScript {
    name = finalAttrs.pname;
    owner = finalAttrs.src.owner;
    repo = finalAttrs.src.repo;
  };

  meta = with lib; {
    description = "OpenCL compilation with clang compiler";
    homepage = "https://github.com/RadeonOpenCompute/clang-ocl";
    license = with licenses; [ mit ];
    maintainers = teams.rocm.members;
    platforms = platforms.linux;
    broken = versions.minor finalAttrs.version != versions.minor rocmPackages_5.llvm.llvm.version;
  };
})
