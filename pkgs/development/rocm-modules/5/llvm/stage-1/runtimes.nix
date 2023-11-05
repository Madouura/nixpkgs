{ lib
, callPackage
, stdenv ? { }
, rocmPackages ? { }
}:

let
  targetName = "runtimes";
in callPackage ../generic.nix {
  inherit stdenv rocmPackages targetName;
  buildDocs = false;
  buildMan = false;
  buildTests = false;
  targetDir = targetName;

  targetRuntimes = [
    "libunwind"
    "libcxxabi"
    "libcxx"
    "compiler-rt"
  ];

  extraBuildInputs = with rocmPackages.llvm; [ llvm ];

  extraCMakeFlags = [
    (lib.cmakeBool "LIBCXX_INCLUDE_BENCHMARKS" false)
    (lib.cmakeFeature "LIBCXX_CXX_ABI" "libcxxabi")
  ];

  extraLicenses = [ lib.licenses.mit ];
}
