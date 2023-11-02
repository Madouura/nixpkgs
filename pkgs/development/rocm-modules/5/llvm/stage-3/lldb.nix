{ lib
, callPackage
, xz
, swig
, lua5_3
, graphviz
, gtest
, python3Packages
, stdenv ? { }
, rocmPackages ? { }
}:

let
  targetName = "lldb";
in callPackage ../generic.nix {
  inherit stdenv rocmPackages targetName;
  targetDir = targetName;
  extraNativeBuildInputs = [ python3Packages.sphinx-automodapi ];

  extraBuildInputs = [
    xz
    swig
    lua5_3
    graphviz
    gtest
  ];

  extraCMakeFlags = [
    (lib.cmakeBool "LLDB_INCLUDE_TESTS" true)
    (lib.cmakeBool "LLDB_INCLUDE_UNITTESTS" true)
    (lib.cmakeFeature "LLDB_TEST_COMPILER" "${rocmPackages.llvm.clang}/bin/clang")
  ];

  extraPostPatch = ''
    clang_version="$(clang -v 2>&1 | grep "clang version " | grep -E -o "[0-9.-]+")"

    substituteInPlace cmake/modules/LLDBConfig.cmake \
      --replace "\''${CANDIDATE}/clang/\''${LLDB_CLANG_RESOURCE_DIR_NAME}" \
        "${rocmPackages.llvm.clang.cc}/lib/clang/$clang_version"

    # Hangs indefinitely
    rm test/API/functionalities/process_group/TestChangeProcessGroup.py
    rm test/API/tools/lldb-vscode/attach/TestVSCode_attach.py
    rm test/API/tools/lldb-vscode/disconnect/TestVSCode_disconnect.py

    # Most seem to be actual failures, others are C++ includes not being found...
    cat ${./1002-lldb-failing-tests.list} | xargs -d \\n rm
  '';

  checkTargets = [ "check-${targetName}" ];
}
