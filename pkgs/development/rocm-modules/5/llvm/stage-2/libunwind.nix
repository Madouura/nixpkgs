{ callPackage
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
    "-DLIBUNWIND_INCLUDE_DOCS=ON"
    "-DLIBUNWIND_INCLUDE_TESTS=ON"
    "-DLIBUNWIND_USE_COMPILER_RT=ON"
  ];

  extraPostPatch = ''
    # `command had no output on stdout or stderr` (Says these unsupported tests)
    chmod +w -R ../libunwind/test
    rm ../libunwind/test/floatregister.pass.cpp
    rm ../libunwind/test/unwind_leaffunction.pass.cpp
    rm ../libunwind/test/libunwind_02.pass.cpp
  '';
}
