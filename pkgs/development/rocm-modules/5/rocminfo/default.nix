{ lib
, stdenv
, fetchFromGitHub
, commonNativeBuildInputs
, commonCMakeFlags
, rocmUpdateScript
, rocmPackages_5
, python3
, pciutils
, callPackage
  # `rocminfo` requires that the calling user have a password and be in
  # the video group. If we let `rocm_agent_enumerator` rely upon
  # `rocminfo`'s output, then it, too, has those requirements. Instead,
  # we can specify the GPU targets for this system (e.g. "gfx803" for
  # Polaris) such that no system call is needed for downstream
  # compilers to determine the desired target.
, gpuTargets ? [ ]
}:

stdenv.mkDerivation (finalAttrs: {
  pname = finalAttrs.passthru.prefixName;
  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocminfo";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-UzOo2qDT/uM+vdGdBM4pV5e143mfa+/6sZLBExOO26g=";
  };

  nativeBuildInputs = commonNativeBuildInputs;
  buildInputs = with rocmPackages_5; [ rocm-runtime ];

  propagatedBuildInputs = [
    python3
    pciutils
  ];

  cmakeFlags = [
    (lib.cmakeFeature "ROCRTST_BLD_TYPE" "Release")
  ] ++ commonCMakeFlags;

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

  passthru = {
    prefixName = "rocminfo";

    tests = {
      rocminfo = callPackage ./tests/rocminfo.nix { testedPackage = finalAttrs.finalPackage; };
      rocm_agent_enumerator = callPackage ./tests/rocm_agent_enumerator.nix { testedPackage = finalAttrs.finalPackage; };
    };

    impureTests = {
      rocminfo = callPackage ../impureTests.nix {
        testedPackage = finalAttrs.finalPackage;
        testName = "rocminfo";
        isExecutable = true;
      };

      rocm_agent_enumerator = callPackage ../impureTests.nix {
        testedPackage = finalAttrs.finalPackage;
        testName = "rocm_agent_enumerator";
        isExecutable = true;
      };
    };

    updateScript = rocmUpdateScript {
      name = finalAttrs.pname;
      owner = finalAttrs.src.owner;
      repo = finalAttrs.src.repo;
    };
  };

  meta = with lib; {
    description = "ROCm Application for Reporting System Info";
    homepage = "https://github.com/RadeonOpenCompute/rocminfo";
    license = licenses.ncsa;
    maintainers = with maintainers; [ lovesegfault ] ++ teams.rocm.members;
    platforms = platforms.linux;
    broken = versions.minor finalAttrs.version != versions.minor rocmPackages_5.llvm.llvm.version;
  };
})
