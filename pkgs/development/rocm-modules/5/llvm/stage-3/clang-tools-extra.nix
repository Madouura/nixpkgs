{ lib
, callPackage
, gtest
, stdenv ? { }
, rocmPackages ? { }
}:

callPackage ../generic.nix {
  inherit stdenv rocmPackages;
  buildTests = false; # `invalid operands to binary expression ('std::basic_stringstream<char>' and 'const llvm::StringRef')`
  targetName = "clang-tools-extra";

  targetProjects = [
    "clang"
    "clang-tools-extra"
  ];

  extraBuildInputs = [ gtest ];

  extraCMakeFlags = [
    (lib.cmakeBool "LLVM_INCLUDE_DOCS" false)
    (lib.cmakeBool "LLVM_INCLUDE_TESTS" false)
    (lib.cmakeBool "CLANG_INCLUDE_DOCS" false)
    (lib.cmakeBool "CLANG_INCLUDE_TESTS" true)
    (lib.cmakeBool "CLANG_TOOLS_EXTRA_INCLUDE_DOCS" true)
  ];

  extraPostInstall = with rocmPackages.llvm; ''
    # Remove LLVM and Clang
    for path in `find ${llvm} ${clang-unwrapped}`; do
      if [ $path != ${llvm} ] && [ $path != ${clang-unwrapped} ]; then
        rm -f $out''${path#${llvm}} $out''${path#${clang-unwrapped}} || true
      fi
    done

    # Cleanup empty directories
    find $out -type d -empty -delete
  '';

  requiredSystemFeatures = [ "big-parallel" ];
}
