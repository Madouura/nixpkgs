{ callPackage
, stdenv ? { }
, rocmPackages ? { }
}:

let
  targetName = "lld";
in callPackage ../generic.nix {
  inherit stdenv rocmPackages targetName;
  buildMan = false; # No man pages to build
  targetDir = targetName;
  extraBuildInputs = with rocmPackages.llvm; [ llvm ];
  checkTargets = [ "check-${targetName}" ];
}
