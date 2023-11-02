{ callPackage
, rocmPackages ? { }
}:

{
  version = rocmPackages.llvm.llvm.version;
  stdenv = rocmPackages.llvm.rocmClangStdenv;

  rocmUpdateScript = callPackage ../common/update.nix {
    inherit (rocmPackages.util) version;
  };

  rocmMakeImpureTest = callPackage ../common/make-impure-test.nix {
    inherit (rocmPackages.util) version;
  };

  rocmCallPackage = path: attrs: (callPackage ../common/generic.nix {
    inherit (rocmPackages.util) stdenv;
    inherit rocmPackages;
  } // attrs).overrideAttrs (callPackage path attrs);

  rocmStdCallPackage = path: attrs: (callPackage ../common/generic.nix {
    inherit rocmPackages;
  } // attrs).overrideAttrs (callPackage path attrs);
}
