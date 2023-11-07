{ lib
, callPackage
, stdenv ? { }
, rocmPackages ? { }
}:

let
  targetName = "libcxx";
in callPackage ../generic.nix {
  inherit stdenv rocmPackages targetName;
  buildMan = false; # No man pages to build
  targetDir = "runtimes";

  targetRuntimes = [
    "libunwind"
    "libcxxabi"
    targetName
  ];

  extraCMakeFlags = [
    (lib.cmakeBool "LIBCXX_INCLUDE_DOCS" true)
    (lib.cmakeBool "LIBCXX_INCLUDE_TESTS" true)
    (lib.cmakeBool "LIBCXX_USE_COMPILER_RT" true)
    (lib.cmakeFeature "LIBCXX_CXX_ABI" "libcxxabi")

    # Workaround having to build combined
    (lib.cmakeBool "LIBUNWIND_INCLUDE_DOCS" false)
    (lib.cmakeBool "LIBUNWIND_INCLUDE_TESTS" false)
    (lib.cmakeBool "LIBUNWIND_USE_COMPILER_RT" true)
    (lib.cmakeBool "LIBUNWIND_INSTALL_LIBRARY" false)
    (lib.cmakeBool "LIBUNWIND_INSTALL_HEADERS" false)
    (lib.cmakeBool "LIBCXXABI_INCLUDE_TESTS" false)
    (lib.cmakeBool "LIBCXXABI_USE_LLVM_UNWINDER" true)
    (lib.cmakeBool "LIBCXXABI_USE_COMPILER_RT" true)
    (lib.cmakeBool "LIBCXXABI_INSTALL_LIBRARY" false)
    (lib.cmakeBool "LIBCXXABI_INSTALL_HEADERS" false)
  ];

  # Most of these can't find `bash` or `mkdir`, might just be hard-coded paths, or PATH is altered
  extraPostPatch = ''
    chmod +w -R ../libcxx/test/{libcxx,std}
    cat ${./1000-libcxx-failing-tests.list} | xargs -d \\n rm
  '';
}
