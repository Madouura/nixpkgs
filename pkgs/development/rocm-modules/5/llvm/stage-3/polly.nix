{ callPackage
, stdenv ? { }
, rocmPackages ? { }
}:

let
  targetName = "polly";
in callPackage ../generic.nix {
  inherit stdenv rocmPackages targetName;
  targetDir = targetName;

  extraPostPatch = ''
    # `add_library cannot create target "llvm_gtest" because an imported target with the same name already exists`
    substituteInPlace CMakeLists.txt \
      --replace "NOT TARGET gtest" "FALSE"
  '';

  checkTargets = [ "check-${targetName}" ];
}
