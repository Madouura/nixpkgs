{ lib
, callPackage
, graphviz
, python3Packages
, stdenv ? { }
, rocmPackages ? { }
}:

let
  targetName = "flang";
in callPackage ../generic.nix {
  inherit stdenv rocmPackages targetName;
  targetDir = targetName;

  extraNativeBuildInputs = [
    graphviz
    python3Packages.sphinx-markdown-tables
  ];

  extraBuildInputs = [ rocmPackages.llvm.mlir ];

  extraCMakeFlags = with rocmPackages.llvm; [
    (lib.cmakeFeature "CLANG_DIR" "${clang}/resource-root/lib/cmake/clang")
    (lib.cmakeFeature "MLIR_TABLEGEN_EXE" "${mlir}/bin/mlir-tblgen")
    (lib.cmakeFeature "CLANG_TABLEGEN_EXE" "${clang}/bin/clang-tblgen")
    # `The dependency target "Bye" of target ...`
    (lib.cmakeBool "FLANG_INCLUDE_TESTS" false)
  ];

  extraPostPatch = with rocmPackages.llvm; ''
    for path in include/flang/Optimizer/{Dialect,HLFIR,Transforms,CodeGen}; do
      ln -s ${mlir}/bin/mlir-tblgen $path
    done
  '';

  # `flang/lib/Semantics/check-omp-structure.cpp:1905:1: error: no member named 'v' in 'Fortran::parser::OmpClause::OmpxDynCgroupMem'`
  isBroken = true;
}
