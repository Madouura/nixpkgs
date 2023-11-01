{ lib
, fetchFromGitHub
, rocmPackages
, libdrm
, numactl
, callPackage
, buildShared ? false
, buildTests ? false
}:

(finalAttrs: oldAttrs: {
  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCT-Thunk-Interface";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-jAMBks2/JaXiA45B3qvLHY8fPeFcr1GHT5Jieuduqhw=";
  };

  nativeBuildInputs = rocmPackages.util.commonNativeBuildInputs;

  buildInputs = [
    libdrm
    numactl
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED_LIBS" buildShared)
  ] ++ rocmPackages.util.commonCMakeFlags;

  passthru = oldAttrs.passthru // {
    prefixName = "rocm-thunk";
    prefixNameSuffix = "-variants";
    inherit buildShared buildTests;

    unparsedTests = {
      kfdtest = finalAttrs.finalPackage.overrideAttrs (callPackage ./tests/kfdtest.nix {
        testedPackage = finalAttrs.finalPackage;
        inherit rocmPackages;
      });

      reopen = finalAttrs.finalPackage.overrideAttrs (callPackage ./tests/reopen.nix {
        testedPackage = rocmPackages.rocm-thunk-variants.shared;
      });
    };

    impureTests = {
      reopen = rocmPackages.util.rocmMakeImpureTest {
        testedPackage = rocmPackages.rocm-thunk-variants.shared;
        testName = "reopen";
        isExecutable = true;
      };
    };
  };

  meta = with lib; oldAttrs.meta // {
    description = "Radeon open compute thunk interface";
    homepage = "https://github.com/RadeonOpenCompute/ROCT-Thunk-Interface";
    license = with licenses; [ bsd2 mit ];
    maintainers = with maintainers; [ lovesegfault ] ++ oldAttrs.meta.maintainers;
  };
})
