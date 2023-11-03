{ lib
, fetchFromGitHub
, libdrm
, numactl
, callPackage
, rocmPackages ? { }
, rocmMkDerivation ? { }
, ...
}:

{ buildShared ? false }:

rocmMkDerivation {
  inherit buildShared;
} (finalAttrs: oldAttrs: {
  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCT-Thunk-Interface";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-jAMBks2/JaXiA45B3qvLHY8fPeFcr1GHT5Jieuduqhw=";
  };

  buildInputs = [
    libdrm
    numactl
  ];

  cmakeFlags = oldAttrs.cmakeFlags ++ [
    (lib.cmakeBool "BUILD_SHARED_LIBS" buildShared)
  ];

  passthru = oldAttrs.passthru // {
    prefixName = "rocm-thunk";
    prefixNameSuffix = "-variants";

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
    maintainers = with maintainers; oldAttrs.meta.maintainers ++ [ lovesegfault ];
  };
})
