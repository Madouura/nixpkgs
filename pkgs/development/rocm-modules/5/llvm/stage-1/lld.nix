{ callPackage
, rocmUpdateScript
, llvm
}:

callPackage ../generic.nix rec {
  inherit rocmUpdateScript;
  buildMan = false; # No man pages to build
  targetName = "lld";
  targetDir = targetName;
  extraBuildInputs = [ llvm ];
  checkTargets = [ "check-${targetName}" ];
}
