{ lib
, callPackage
, glibc
, stdenv ? { }
, rocmPackages ? { }
}:

let
  targetName = "compiler-rt";
in callPackage ../generic.nix {
  inherit stdenv rocmPackages targetName;
  buildDocs = false; # No documentation to build
  buildMan = false; # No man pages to build
  targetDir = "runtimes";

  targetRuntimes = [
    "libunwind"
    "libcxxabi"
    "libcxx"
    targetName
  ];

  extraCMakeFlags = [
    (lib.cmakeBool "COMPILER_RT_INCLUDE_TESTS" true)
    (lib.cmakeBool "COMPILER_RT_USE_LLVM_UNWINDER" true)
    (lib.cmakeFeature "COMPILER_RT_CXX_LIBRARY" "libcxx")
    # We can't run most of these
    (lib.cmakeBool "COMPILER_RT_CAN_EXECUTE_TESTS" false)

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
    (lib.cmakeBool "LIBCXX_INCLUDE_DOCS" false)
    (lib.cmakeBool "LIBCXX_INCLUDE_TESTS" false)
    (lib.cmakeBool "LIBCXX_USE_COMPILER_RT" true)
    (lib.cmakeFeature "LIBCXX_CXX_ABI" "libcxxabi")
    (lib.cmakeBool "LIBCXX_INSTALL_LIBRARY" false)
    (lib.cmakeBool "LIBCXX_INSTALL_HEADERS" false)
  ];

  extraPostPatch = ''
    # `No such file or directory: 'ldd'`
    substituteInPlace ../compiler-rt/test/lit.common.cfg.py \
      --replace "'ldd'," "'${glibc.bin}/bin/ldd',"

    # We can run these
    substituteInPlace ../compiler-rt/test/CMakeLists.txt \
      --replace "endfunction()" "endfunction()''\nadd_subdirectory(builtins)''\nadd_subdirectory(shadowcallstack)"

    # Could not launch llvm-config in /build/source/runtimes/build/bin
    mkdir -p build/bin
    ln -s ${rocmPackages.llvm.llvm}/bin/llvm-config build/bin
  '';

  extraLicenses = [ lib.licenses.mit ];
}
