{ lib
, rocmPackages
, rPackage
, ...
}:

let
  targetName = "runtimes";
in rPackage {
  inherit targetName;
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

  extraBuildInputs = [ rocmPackages.llvm.llvm ];

  extraCMakeFlags = [
    (lib.cmakeBool "LIBCXX_INCLUDE_BENCHMARKS" false)
    (lib.cmakeFeature "LIBCXX_CXX_ABI" "libcxxabi")
  ];

  extraLicenses = [ lib.licenses.mit ];
}
