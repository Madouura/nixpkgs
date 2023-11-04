{ callPackage
, stdenv ? { }
, rocmPackages ? { }
}:

let
  targetName = "pstl";
in callPackage ../generic.nix {
  inherit stdenv rocmPackages targetName;
  buildDocs = false; # No documentation to build
  buildMan = false; # No man pages to build
  buildTests = false; # Too many errors
  targetDir = "runtimes";
  targetRuntimes = [ targetName ];
  checkTargets = [ "check-${targetName}" ];
}
