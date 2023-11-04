{ symlinkJoin
, rocmCallPackage ? { }
}:

let
  packages = {
    static = {
      default = rocmCallPackage ./generic.nix {
        buildShared = false;
        buildTests = false;
      };

      test = rocmCallPackage ./generic.nix {
        buildShared = false;
        buildTests = true;
      };
    };

    shared = {
      default = rocmCallPackage ./generic.nix {
        buildShared = true;
        buildTests = false;
      };

      test = rocmCallPackage ./generic.nix {
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
