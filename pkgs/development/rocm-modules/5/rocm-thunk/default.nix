{ rocmStdCallPackage
, symlinkJoin
}:

let
  static = rocmStdCallPackage ./generic.nix {
    buildShared = false;
  };

  shared = rocmStdCallPackage ./generic.nix {
    buildShared = true;
  };
in {
  inherit static shared;

  full = symlinkJoin {
    name = "${static.prefixName}-full-${static.version}";
    paths = [ static shared ];
  };
}
