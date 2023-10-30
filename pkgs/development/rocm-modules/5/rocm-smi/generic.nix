{ lib
, stdenv
, fetchFromGitHub
, commonNativeBuildInputs
, commonCMakeFlags
, rocmUpdateScript
, rocmPackages_5
, python3Packages
, gtest
, callPackage
, buildShared ? false
}:

stdenv.mkDerivation (finalAttrs: {
  pname = finalAttrs.passthru.prefixName + (
    if buildShared
    then "-shared"
    else "-static"
  );

  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm_smi_lib";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-NZR4jBgKVfpkRNQFPmav1yCZF872LkcrPBNNcBVTLDU=";
  };

  patches = [
    ./0000-fix-cmake-bad-paths.patch
    ./0001-fix-tests.patch
  ];

  nativeBuildInputs = [ python3Packages.wrapPython ] ++ commonNativeBuildInputs;
  buildInputs = [ gtest ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED_LIBS" buildShared)
    (lib.cmakeBool "BUILD_TESTS" true)
  ] ++ commonCMakeFlags;

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace "number(\"5.0.0\"" "number(\"${finalAttrs.version}\"" \
      --replace "PKG_VERSION_MAJOR 1" "PKG_VERSION_MAJOR ${lib.versions.major finalAttrs.version}" \
      --replace "PKG_VERSION_MINOR 0" "PKG_VERSION_MINOR ${lib.versions.minor finalAttrs.version}" \
      --replace "PKG_VERSION_PATCH 0" "PKG_VERSION_PATCH ${lib.versions.patch finalAttrs.version}"

    substituteInPlace cmake_modules/utils.cmake \
      --replace "(get_commits)" "(FALSE)" \
      --replace "message(\"WARNING: Didn't find version_util.sh\")" ""

    # Not an error, but our LLD doesn't seem to recognize it
    # `ld.lld: warning: unknown -z value: noexecheap`
    substituteInPlace CMakeLists.txt cmake_modules/help_package.cmake \
      --replace "-znoexecheap" ""
  '';

  postInstall = ''
    wrapPythonProgramsIn $out/libexec/rocm_smi
    mv $out/libexec/rocm_smi/.rsmiBindings.py-wrapped $out/libexec/rocm_smi/rsmiBindings.py
  '';

  passthru = {
    prefixName = "rocm-smi";

    tests = {
      # Test requires the shared variant
      rocm-smi = callPackage ./tests/rocm-smi.nix {
        testedPackage = rocmPackages_5.rocm-smi-variants.shared;
      };

      # Test requires the shared variant
      rsmitst = callPackage ./tests/rsmitst.nix {
        testedPackage = rocmPackages_5.rocm-smi-variants.shared;
      };
    };

    impureTests = {
      rocm-smi = callPackage ../impureTests.nix {
        testedPackage = rocmPackages_5.rocm-smi-variants.shared;
        testName = "rocm-smi";
        isNested = true;
        isExecutable = true;
      };

      rsmitst = callPackage ../impureTests.nix {
        testedPackage = rocmPackages_5.rocm-smi-variants.shared;
        testName = "rsmitst";
        isNested = true;
        isExecutable = true;
        bypassTestScript = true;
      };
    };

    updateScript = rocmUpdateScript {
      name = finalAttrs.pname;
      owner = finalAttrs.src.owner;
      repo = finalAttrs.src.repo;
    };
  };

  meta = with lib; {
    description = "System management interface for AMD GPUs supported by ROCm";
    homepage = "https://github.com/RadeonOpenCompute/rocm_smi_lib";
    license = with licenses; [ ncsa ];
    maintainers = with maintainers; [ lovesegfault ] ++ teams.rocm.members;
    platforms = platforms.linux;
    broken = versions.minor finalAttrs.version != versions.minor rocmPackages_5.llvm.llvm.version;
  };
})
