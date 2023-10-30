{ lib
, stdenv
, fetchFromGitHub
, commonNativeBuildInputs
, commonCMakeFlags
, rocmUpdateScript
, rocmPackages_5
, libdrm
, numactl
, callPackage
, buildShared ? false
}:

stdenv.mkDerivation (finalAttrs: {
  pname = finalAttrs.passthru.prefixName + (
    if buildShared
    then "-shared"
    else "-static"
  );

  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCT-Thunk-Interface";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-jAMBks2/JaXiA45B3qvLHY8fPeFcr1GHT5Jieuduqhw=";
  };

  nativeBuildInputs = commonNativeBuildInputs;

  buildInputs = [
    libdrm
    numactl
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED_LIBS" buildShared)
  ] ++ commonCMakeFlags;

  passthru = {
    prefixName = "rocm-thunk";

    tests = {
      kfdtest = finalAttrs.finalPackage.overrideAttrs (callPackage ./tests/kfdtest.nix { });

      reopen = finalAttrs.finalPackage.overrideAttrs (callPackage ./tests/reopen.nix {
        testedPackage = rocmPackages_5.rocm-thunk-variants.shared;
      });
    };

    impureTests = {
      reopen = callPackage ../impureTests.nix {
        testedPackage = rocmPackages_5.rocm-thunk-variants.shared;
        testName = "reopen";
        isNested = true;
        isExecutable = true;
      };
    };

    updateScript = rocmUpdateScript {
      name = finalAttrs.pname;
      owner = finalAttrs.src.owner;
      repo = finalAttrs.src.repo;
    };
  };

  meta = with lib; {
    description = "Radeon open compute thunk interface";
    homepage = "https://github.com/RadeonOpenCompute/ROCT-Thunk-Interface";
    license = with licenses; [ bsd2 mit ];
    maintainers = with maintainers; [ lovesegfault ] ++ teams.rocm.members;
    platforms = platforms.linux;
    broken = versions.minor finalAttrs.version != versions.minor rocmPackages_5.llvm.llvm.version;
  };
})
