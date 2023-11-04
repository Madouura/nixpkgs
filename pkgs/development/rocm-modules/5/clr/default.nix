{ symlinkJoin
, rocmCallPackage ? { }
}:

let
  packages = let
    # Don't call these unless you need the source or something.
    # `clr` has all you need otherwise.
    hip-common = rocmCallPackage ./hip-common.nix { };
    hipcc = rocmCallPackage ./hipcc.nix { };
  in {
    inherit hip-common hipcc;

    static = {
      default = rocmCallPackage ./generic.nix {
        inherit hip-common hipcc;
        buildShared = false;
        buildTests = false;
      };

      test = rocmCallPackage ./generic.nix {
        inherit hip-common hipcc;
        buildShared = false;
        buildTests = true;
      };
    };

    shared = {
      default = rocmCallPackage ./generic.nix {
        inherit hip-common hipcc;
        buildShared = true;
        buildTests = false;
      };

      test = rocmCallPackage ./generic.nix {
        inherit hip-common hipcc;
        buildShared = true;
        buildTests = true;
      };
    };
  };
in packages // {
  full = with packages; symlinkJoin {
    name = "${static.default.prefixName}-full-${static.default.version}";
    paths = [ static.default shared.default ];
  };
}
