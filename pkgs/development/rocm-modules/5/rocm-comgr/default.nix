{ stdenv
, callPackage
, commonNativeBuildInputs
, commonCMakeFlags
, rocmUpdateScript
, symlinkJoin
}:

let
  static = callPackage ./generic.nix {
    inherit stdenv commonNativeBuildInputs commonCMakeFlags rocmUpdateScript;
    buildShared = false;
  };

  shared = static.override { buildShared = true; };
in {
  inherit static shared;

  full = symlinkJoin {
    name = "${static.prefixName}-full-${static.version}";
    paths = [ static shared ];
  };
}
