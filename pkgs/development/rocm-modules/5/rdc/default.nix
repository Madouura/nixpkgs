{ symlinkJoin
, rocmCallPackage ? { }
}:

let
  packages = {
    default = rocmCallPackage ./generic.nix { buildTests = false; };
    test = rocmCallPackage ./generic.nix { buildTests = true; };
  };
in packages
