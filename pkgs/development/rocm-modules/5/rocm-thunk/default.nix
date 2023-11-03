{ symlinkJoin
, rocmCallPackage ? { }
}:

let
  packages = {
    static = rocmCallPackage ./generic.nix { buildShared = false; };
    shared = rocmCallPackage ./generic.nix { buildShared = true; };
  };
in packages // {
  full = with packages; symlinkJoin {
    name = "${static.prefixName}-full-${static.version}";
    paths = [ static shared ];
  };
}
