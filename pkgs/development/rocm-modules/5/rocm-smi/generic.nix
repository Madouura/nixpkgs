{ lib
, fetchFromGitHub
, python3Packages
, gtest
, callPackage
, rocmPackages ? { }
, rocmMkDerivation ? { }
, ...
}:

{
  buildShared ? false
, buildTests ? false
}:

rocmMkDerivation {
  inherit buildShared buildTests;
} (finalAttrs: oldAttrs: {
  pname =
    oldAttrs.pname
  + (
    if buildTests
    then "-test"
    else "-default"
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
  ] ++ lib.optionals buildTests [
    ./0001-fix-tests.patch
  ];

  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ python3Packages.wrapPython ];
  buildInputs = lib.optionals buildTests [ gtest ];
  propagatedBuildInputs = [ python3Packages.python ];

  cmakeFlags = oldAttrs.cmakeFlags ++ [
    (lib.cmakeBool "BUILD_SHARED_LIBS" buildShared)
    (lib.cmakeBool "BUILD_TESTS" buildTests)
  ];

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace "number(\"5.0.0\"" "number(\"${finalAttrs.version}\"" \
      --replace "PKG_VERSION_MAJOR 1" "PKG_VERSION_MAJOR ${lib.versions.major finalAttrs.version}" \
      --replace "PKG_VERSION_MINOR 0" "PKG_VERSION_MINOR ${lib.versions.minor finalAttrs.version}" \
      --replace "PKG_VERSION_PATCH 0" "PKG_VERSION_PATCH ${lib.versions.patch finalAttrs.version}"

    substituteInPlace cmake_modules/utils.cmake \
      --replace "(get_commits)" "(FALSE)" \
      --replace "message(\"WARNING: Didn't find version_util.sh\")" ""
  '';

  postInstall = ''
    wrapPythonProgramsIn $out/libexec/rocm_smi
    mv $out/libexec/rocm_smi/.rsmiBindings.py-wrapped $out/libexec/rocm_smi/rsmiBindings.py
  '';

  passthru = oldAttrs.passthru // {
    prefixName = "rocm-smi";
    prefixNameSuffix = "-variants";

    unparsedTests = {
      # Test requires the shared variant
      rocm-smi = "${rocmPackages.rocm-smi-variants.shared.default}/bin/rocm-smi";
      # Test requires the (shared) test variant
      rsmitst-shared = "${rocmPackages.rocm-smi-variants.shared.test}/share/rocm_smi/rsmitst_tests/rsmitst";
      # Test requires the (static) test variant
      rsmitst-static = "${rocmPackages.rocm-smi-variants.static.test}/share/rocm_smi/rsmitst_tests/rsmitst";
    };

    impureTests = {
      rocm-smi = rocmPackages.util.rocmMakeImpureTest {
        testedPackage = rocmPackages.rocm-smi-variants.shared.default;
        testName = "rocm-smi";
        isExecutable = true;
      };

      rsmitst-shared = rocmPackages.util.rocmMakeImpureTest {
        testedPackage = rocmPackages.rocm-smi-variants.shared.test;
        testName = "rsmitst-shared";
        isExecutable = true;
        bypassTestScript = true;
      };

      rsmitst-static = rocmPackages.util.rocmMakeImpureTest {
        testedPackage = rocmPackages.rocm-smi-variants.static.test;
        testName = "rsmitst-static";
        isExecutable = true;
        bypassTestScript = true;
      };
    };
  };

  meta = with lib; oldAttrs.meta // {
    description = "System management interface for AMD GPUs supported by ROCm";
    homepage = "https://github.com/RadeonOpenCompute/rocm_smi_lib";
    license = with licenses; [ ncsa ];
    maintainers = with maintainers; oldAttrs.meta.maintainers ++ [ lovesegfault ];
  };
})
