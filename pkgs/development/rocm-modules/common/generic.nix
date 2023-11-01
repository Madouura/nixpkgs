{ lib
, stdenv ? { }
, rocmPackages ? { }
, buildShared ? null
, buildDocs ? false
, buildTests ? false
, buildExamples ? false
}:

stdenv.mkDerivation (finalAttrs: {
  pname =
    finalAttrs.passthru.prefixName
  + lib.optionalString (finalAttrs.passthru.buildShared != null) (
      if finalAttrs.passthru.buildShared
      then "-shared"
      else "-static"
    );

  outputs = [
    "out"
  ] ++ lib.optionals finalAttrs.passthru.buildDocs [
    "doc"
  ] ++ lib.optionals finalAttrs.passthru.buildExamples [
    "example"
  ];

  doCheck = finalAttrs.passthru.buildTests;

  passthru = {
    inherit buildShared buildDocs buildTests buildExamples;

    updateScript = rocmPackages.util.rocmUpdateScript {
      name = finalAttrs.passthru.prefixName;
      owner = finalAttrs.src.owner;
      repo = finalAttrs.src.repo;
    };
  };

  meta = with lib; {
    maintainers = teams.rocm.members;
    # ROCm is only really supported on `x86_64-linux`
    # Some ROCm packages can override this
    platforms = [ "x86_64-linux" ];

    broken =
      # Don't allow major version upgrades; They need to be put into `rocmPackages_N`
      versions.major finalAttrs.version != versions.major rocmPackages.util.version ||
      # Don't allow a version difference bigger than a patch
      versions.minor finalAttrs.version != versions.minor rocmPackages.util.version;
  };
})
