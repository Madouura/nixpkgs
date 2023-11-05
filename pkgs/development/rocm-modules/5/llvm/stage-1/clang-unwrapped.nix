{ lib
, callPackage
, stdenv ? { }
, rocmPackages ? { }
}:

callPackage ../generic.nix {
  inherit stdenv rocmPackages;
  targetName = "clang-unwrapped";
  targetDir = "clang";
  extraBuildInputs = with rocmPackages.llvm; [ llvm ];

  extraCMakeFlags = [
    (lib.cmakeBool "CLANG_INCLUDE_DOCS" true)
    (lib.cmakeBool "CLANG_INCLUDE_TESTS" true)
  ];

  extraPostPatch = ''
    # Looks like they forgot to add finding libedit to the standalone build
    ln -s ../cmake/Modules/FindLibEdit.cmake cmake/modules

    substituteInPlace CMakeLists.txt \
      --replace "include(CheckIncludeFile)" "include(CheckIncludeFile)''\nfind_package(LibEdit)"

    # `No such file or directory: '/build/source/clang/tools/scan-build/bin/scan-build'`
    rm test/Analysis/scan-build/*.test
    rm test/Analysis/scan-build/rebuild_index/rebuild_index.test

    # `does not depend on a module exporting 'baz.h'`
    rm test/Modules/header-attribs.cpp

    # We do not have HIP or the ROCm stack available yet
    rm test/Driver/hip-options.hip

    # ???? `ld: cannot find crti.o: No such file or directory` linker issue?
    rm test/Interpreter/dynamic-library.cpp

    # `fatal error: 'stdio.h' file not found`
    rm test/OpenMP/amdgcn_emit_llvm.c
  '';

  extraPostInstall = ''
    cp -a bin/clang-tblgen $out/bin
  '';

  requiredSystemFeatures = [ "big-parallel" ];
}
