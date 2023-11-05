{ lib
, callPackage
, stdenv ? { }
, rocmPackages ? { }
}:

let
  targetName = "libcxxabi";
in callPackage ../generic.nix {
  inherit stdenv rocmPackages targetName;
  buildDocs = false; # No documentation to build
  buildMan = false; # No man pages to build
  targetDir = "runtimes";

  targetRuntimes = [
    "libunwind"
    targetName
    "libcxx"
  ];

  extraCMakeFlags = [
    (lib.cmakeBool "LIBCXXABI_INCLUDE_TESTS" true)
    (lib.cmakeBool "LIBCXXABI_USE_LLVM_UNWINDER" true)
    (lib.cmakeBool "LIBCXXABI_USE_COMPILER_RT" true)

    # Workaround having to build combined
    (lib.cmakeBool "LIBUNWIND_INCLUDE_DOCS" false)
    (lib.cmakeBool "LIBUNWIND_INCLUDE_TESTS" false)
    (lib.cmakeBool "LIBUNWIND_USE_COMPILER_RT" true)
    (lib.cmakeBool "LIBUNWIND_INSTALL_LIBRARY" false)
    (lib.cmakeBool "LIBUNWIND_INSTALL_HEADERS" false)
    (lib.cmakeBool "LIBCXX_INCLUDE_DOCS" false)
    (lib.cmakeBool "LIBCXX_INCLUDE_TESTS" false)
    (lib.cmakeBool "LIBCXX_USE_COMPILER_RT" true)
    (lib.cmakeFeature "LIBCXX_CXX_ABI" "libcxxabi")
    (lib.cmakeBool "LIBCXX_INSTALL_LIBRARY" false)
    (lib.cmakeBool "LIBCXX_INSTALL_HEADERS" false)
  ];
}
