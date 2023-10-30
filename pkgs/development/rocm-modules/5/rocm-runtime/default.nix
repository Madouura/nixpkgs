{ stdenv
, callPackage
, commonNativeBuildInputs
, commonCMakeFlags
, rocmUpdateScript
, symlinkJoin
}:

let
  generic = callPackage ./generic.nix {
    inherit stdenv commonNativeBuildInputs commonCMakeFlags rocmUpdateScript;
  };

  packages = {
    static = rec {
      default = generic.override {
        buildShared = false;
        imageSupport = false;
      };

      image = default.override { imageSupport = true; };
    };

    shared = rec {
      default = generic.override {
        buildShared = true;
        imageSupport = false;
      };

      image = default.override { imageSupport = true; };
    };
  };
in packages // {
  full = symlinkJoin {
    name = "${generic.prefixName}-full-${generic.version}";
    paths = with packages; [ static.image shared.image ];
  };
}
