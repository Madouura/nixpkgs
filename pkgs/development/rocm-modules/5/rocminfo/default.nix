{ lib
, fetchFromGitHub
, python3
, pciutils
, callPackage
, rocmPackages ? { }
, rocmMkDerivation ? { }
, ...
}:

{ # `rocminfo` requires that the calling user have a password and be in
  # the video group. If we let `rocm_agent_enumerator` rely upon
  # `rocminfo`'s output, then it, too, has those requirements. Instead,
  # we can specify the GPU targets for this system (e.g. "gfx803" for
  # Polaris) such that no system call is needed for downstream
  # compilers to determine the desired target.
  gpuTargets ? [ ]
}:

rocmMkDerivation { } (finalAttrs: oldAttrs: {
  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocminfo";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-UzOo2qDT/uM+vdGdBM4pV5e143mfa+/6sZLBExOO26g=";
  };

  buildInputs = with rocmPackages; [ rocm-runtime ];

  propagatedBuildInputs = [
    python3
    pciutils
  ];

  cmakeFlags = oldAttrs.cmakeFlags ++ [
    (lib.cmakeFeature "ROCRTST_BLD_TYPE" "Release")
  ];

  postPatch = ''
    patchShebangs rocm_agent_enumerator

    substituteInPlace CMakeLists.txt \
      --replace "PKG_VERSION_MAJOR 1" "PKG_VERSION_MAJOR ${lib.versions.major finalAttrs.version}" \
      --replace "PKG_VERSION_MINOR 0" "PKG_VERSION_MINOR ${lib.versions.minor finalAttrs.version}" \
      --replace "PKG_VERSION_PATCH 0" "PKG_VERSION_PATCH ${lib.versions.patch finalAttrs.version}" \
      --replace "number(\"1.0.0\"" "number(\"${finalAttrs.version}\""

    substituteInPlace rocm_agent_enumerator \
      --replace "/usr/bin/lspci" "${pciutils}/bin/lscpi"

    substituteInPlace cmake_modules/utils.cmake \
      --replace "(get_commits)" "(FALSE)" \
      --replace "message(\"WARNING: Didn't find version_util.sh\")" ""
  '';

  postInstall = lib.optionalString (gpuTargets != [ ]) ''
    echo "${lib.concatStringsSep "\n" gpuTargets}" > $out/bin/target.lst
  '';

  passthru = oldAttrs.passthru // {
    prefixName = "rocminfo";

    unparsedTests = {
      rocminfo = "${finalAttrs.finalPackage}/bin/rocminfo";
      rocm_agent_enumerator = "${finalAttrs.finalPackage}/bin/rocm_agent_enumerator";
    };

    impureTests = {
      rocminfo = rocmPackages.util.rocmMakeImpureTest {
        testedPackage = finalAttrs.finalPackage;
        testName = "rocminfo";
        isExecutable = true;
        executableSuffix = " | grep -E 'Name: +gfx[^0]|Device Type: +GPU'";
      };

      rocm_agent_enumerator = rocmPackages.util.rocmMakeImpureTest {
        testedPackage = finalAttrs.finalPackage;
        testName = "rocm_agent_enumerator";
        isExecutable = true;
        executableSuffix = " | grep -E 'gfx[^0]'";
      };
    };
  };

  meta = with lib; oldAttrs.meta // {
    description = "ROCm Application for Reporting System Info";
    homepage = "https://github.com/RadeonOpenCompute/rocminfo";
    license = with licenses; [ ncsa ];
    maintainers = with maintainers; oldAttrs.meta.maintainers ++ [ lovesegfault ];
  };
})
