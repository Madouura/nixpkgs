{ stdenv
, callPackage
, recurseIntoAttrs
, rocmPackages ? { }
}:

{
  stdenv = rocmPackages.llvm.rocmClangStdenv;
  version = rocmPackages.llvm.llvm.version;

  rocmUpdateScript = callPackage ../common/update.nix {
    inherit (rocmPackages.util) version;
  };

  rocmMakeImpureTest = callPackage ../common/make-impure-test.nix {
    inherit (rocmPackages.util) version;
  };

  rocmClangMkDerivation = args: attrs: (
    callPackage ../common/generic.nix {
      inherit (rocmPackages.util) stdenv;
      inherit rocmPackages;
    } args
  ).overrideAttrs attrs;

  rocmGCCMkDerivation = args: attrs: (
    callPackage ../common/generic.nix {
      inherit stdenv rocmPackages;
    } args
  ).overrideAttrs attrs;

  rocmClangCallPackage = path: args:
    callPackage path {
      inherit (rocmPackages.util) stdenv;
      inherit rocmPackages;
      rocmMkDerivation = rocmPackages.util.rocmClangMkDerivation;
    } args;

  rocmGCCCallPackage = path: args:
    callPackage path {
      inherit stdenv rocmPackages;
      rocmMkDerivation = rocmPackages.util.rocmGCCMkDerivation;
    } args;

  recursiveClangCallPackage = path:
    recurseIntoAttrs (callPackage path {
      rocmCallPackage = rocmPackages.util.rocmClangCallPackage;
    });

  recursiveGCCCallPackage = path:
    recurseIntoAttrs (callPackage path {
      rocmCallPackage = rocmPackages.util.rocmGCCCallPackage;
    });
}
