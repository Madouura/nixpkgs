{ lib
, stdenv
, callPackage
, rocmPackages_5;
, pkg-config
, cmake
, ninja
}:

{
  version = rocmPackages_5.llvm.llvm.version;
  stdenv = rocmPackages_5.llvm.rocmClangStdenv;

  commonNativeBuildInputs = with rocmPackages_5; [
    pkg-config
    cmake
    ninja
    rocm-cmake
  ];

  # Manually define CMAKE_INSTALL_<DIR>
  # See: https://github.com/RadeonOpenCompute/rocm-cmake/issues/121
  commonCMakeFlags = [
    (lib.cmakeFeature "CMAKE_INSTALL_BINDIR" "bin")
    (lib.cmakeFeature "CMAKE_INSTALL_LIBDIR" "lib")
    (lib.cmakeFeature "CMAKE_INSTALL_INCLUDEDIR" "include")
    (lib.cmakeFeature "CMAKE_INSTALL_LIBEXECDIR" "libexec")
  ];

  rocmUpdateScript = callPackage ../common/update.nix {
    inherit (rocmPackages_5.util) version;
  };

  rocmMakeImpureTest = callPackage ../common/make-impure-test.nix {
    inherit (rocmPackages_5.util) version;
  };

  rocmCallPackage = path: attrs: (callPackage ../common/generic.nix {
    inherit (rocmPackages_5.util) stdenv;
    rocmPackages = rocmPackages_5;
  }).overrideAttrs (callPackage path attrs);

  rocmStdCallPackage = path: attrs: (callPackage ../common/generic.nix {
    inherit stdenv;
    rocmPackages = rocmPackages_5;
  }).overrideAttrs (callPackage path attrs);
}
