{ lib
, stdenv
, callPackage
, pkg-config
, cmake
, ninja
, rocmPackages ? { }
}:

{
  version = rocmPackages.llvm.llvm.version;
  stdenv = rocmPackages.llvm.rocmClangStdenv;

  commonNativeBuildInputs = with rocmPackages; [
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
    inherit (rocmPackages.util) version;
  };

  rocmMakeImpureTest = callPackage ../common/make-impure-test.nix {
    inherit (rocmPackages.util) version;
  };

  rocmCallPackage = path: attrs: (callPackage ../common/generic.nix {
    inherit (rocmPackages.util) stdenv;
    inherit rocmPackages;
  }).overrideAttrs (callPackage path attrs);

  rocmStdCallPackage = path: attrs: (callPackage ../common/generic.nix {
    inherit stdenv rocmPackages;
  }).overrideAttrs (callPackage path attrs);
}
