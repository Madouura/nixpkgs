{ lib
, pkg-config
, cmake
, ninja
, stdenv ? { }
, rocmPackages ? { }
}:

{ buildShared ? null
, buildDocs ? false
, buildTests ? false
, buildBenchmarks ? false
, buildExamples ? false
}:

stdenv.mkDerivation (finalAttrs: {
  pname =
    finalAttrs.passthru.prefixName
  + lib.optionalString (lib.isBool buildShared) (
      if buildShared
      then "-shared"
      else "-static"
    );

  outputs = [
    "out"
  ] ++ lib.optionals buildDocs [
    "doc"
  ] ++ lib.optionals buildBenchmarks [
    "benchmark"
  ] ++ lib.optionals buildExamples [
    "example"
  ];

  nativeBuildInputs = [
    pkg-config
    cmake
    ninja
    rocmPackages.rocm-cmake
  ];

  # Manually define CMAKE_INSTALL_<DIR>
  # See: https://github.com/RadeonOpenCompute/rocm-cmake/issues/121
  cmakeFlags = [
    (lib.cmakeFeature "CMAKE_INSTALL_BINDIR" "bin")
    (lib.cmakeFeature "CMAKE_INSTALL_LIBDIR" "lib")
    (lib.cmakeFeature "CMAKE_INSTALL_INCLUDEDIR" "include")
    (lib.cmakeFeature "CMAKE_INSTALL_LIBEXECDIR" "libexec")
    (lib.cmakeFeature "CMAKE_INSTALL_SHAREDIR" "share")
    (lib.cmakeFeature "CMAKE_INSTALL_DOCDIR" "share/doc")
    (lib.cmakeFeature "CMAKE_INSTALL_MANDIR" "share/man")
  ];

  doCheck = buildTests;

  passthru.updateScript = rocmPackages.util.rocmUpdateScript {
    name = finalAttrs.passthru.prefixName;
    owner = finalAttrs.src.owner;
    repo = finalAttrs.src.repo;
  };

  meta = with lib; {
    maintainers = teams.rocm.members;
    # ROCm is only really supported on `x86_64-linux`
    # Some ROCm packages can override this
    platforms = [ "x86_64-linux" ];

    broken = with versions;
      # Don't allow major version upgrades; They need to be put into `rocmPackages_N`
      major finalAttrs.version != major rocmPackages.util.version ||
      # Don't allow a version difference bigger than a patch
      minor finalAttrs.version != minor rocmPackages.util.version ||
      # Don't allow passthru to not have the `prefixName` attribute
      !(hasAttr "prefixName" finalAttrs.passthru) ||
      # Don't allow the derivation to not have the `src` attribute
      !(hasAttr "src" finalAttrs);
  };
})
