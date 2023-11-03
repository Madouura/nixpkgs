{ symlinkJoin
, rocmCallPackage ? { }
}:

let
  packages = {
    static = {
      default = rocmCallPackage ./generic.nix {
        buildShared = false;
        imageSupport = false;
      };

      image = rocmCallPackage ./generic.nix {
        buildShared = false;
        imageSupport = true;
      };
    };

    shared = {
      default = rocmCallPackage ./generic.nix {
        buildShared = true;
        imageSupport = false;
      };

      image = rocmCallPackage ./generic.nix {
        buildShared = true;
        imageSupport = true;
      };
    };
  };
in packages // {
  full = with packages; symlinkJoin {
    name = "${static.default.prefixName}-full-${static.default.version}";
    paths = [ static.image shared.image ];
  };
}
