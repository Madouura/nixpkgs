{ lib
, callPackage
, stdenv ? { }
, rocmPackages ? { }
}:

let
  targetName = "libunwind";
in callPackage ../generic.nix {
  inherit stdenv rocmPackages targetName;
  buildMan = false; # No man pages to build
  targetDir = "runtimes";
  targetRuntimes = [ targetName ];

  extraCMakeFlags = [
    (lib.cmakeBool "LIBUNWIND_INCLUDE_DOCS" true)
    (lib.cmakeBool "LIBUNWIND_INCLUDE_TESTS" true)
    (lib.cmakeBool "LIBUNWIND_USE_COMPILER_RT" true)
  ];

  extraPostPatch = ''
    # `command had no output on stdout or stderr` (Says these unsupported tests)
    chmod +w -R ../libunwind/test
    rm ../libunwind/test/floatregister.pass.cpp
    rm ../libunwind/test/unwind_leaffunction.pass.cpp
    rm ../libunwind/test/libunwind_02.pass.cpp
  '';
}
