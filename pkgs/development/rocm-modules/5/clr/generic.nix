{ lib
, stdenv
, fetchFromGitHub
, commonNativeBuildInputs
, commonCMakeFlags
, rocmUpdateScript
, rocmPackages_5
, makeWrapper
, perl
, git
, python3Packages
, numactl
, libGL
, libxml2
, libX11
, glew
, callPackage
, buildShared ? true
}:

let
  wrapperArgs = with rocmPackages_5; [
    "--prefix PATH : $out/bin:${lib.makeBinPath [ llvm.clang rocminfo rocm-smi ]}"
    "--prefix LD_LIBRARY_PATH : $out/lib:${lib.makeLibraryPath [ llvm.clang.cc rocm-comgr rocm-runtime rocm-smi ]}"
    "--set HIP_PLATFORM amd"
    "--set HIP_PATH $out"
    "--set HIP_CLANG_PATH ${llvm.clang}/bin"
    "--set DEVICE_LIB_PATH ${rocm-device-libs}/amdgcn/bitcode"
    "--set HSA_PATH ${rocm-runtime}"
    "--set ROCM_PATH $out"
  ];
in stdenv.mkDerivation (finalAttrs: {
  pname = finalAttrs.passthru.prefixName + (
    if buildShared
    then "-shared"
    else "-static"
  );

  version = "5.7.1";

  outputs = [
    "out"
    "icd"
  ];

  src = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "clr";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-R9ouGOC/HRFiQbWfR43EjafDwpO1dfmsht1Bs9UYimQ=";
    leaveDotGit = true;
  };

  nativeBuildInputs = [
    makeWrapper
    perl
    git
    python3Packages.python
    python3Packages.cppheaderparser
  ] ++ commonNativeBuildInputs;

  buildInputs = [
    numactl
    libGL
    libxml2
    libX11
    glew
  ];

  propagatedBuildInputs = with rocmPackages_5; [
    llvm.clang
    rocm-device-libs
    rocm-comgr
    rocm-runtime
    rocminfo
    rocm-smi
  ];

  cmakeFlags = with rocmPackages_5; [
    # Prefer newer OpenGL libraries
    (lib.cmakeFeature "CMAKE_POLICY_DEFAULT_CMP0072" "NEW")
    # Can't seem to build hip itself as static at the moment
    (lib.cmakeBool "CLR_BUILD_HIP" buildShared)
    (lib.cmakeBool "CLR_BUILD_OCL" true)
    (lib.cmakeFeature "HIP_COMMON_DIR" "${hip-common}")
    (lib.cmakeFeature "HIPCC_BIN_DIR" "${hipcc}/bin")
    (lib.cmakeFeature "HIP_PLATFORM" "amd")
    (lib.cmakeFeature "ROCM_PATH" "${rocminfo}")
    (lib.cmakeFeature "PROF_API_HEADER_PATH" "${roctracer.src}/inc/ext")
    (lib.cmakeBool "BUILD_SHARED_LIBS" buildShared)
    (lib.cmakeBool "BUILD_TESTS" true)
  ] ++ commonCMakeFlags;

  postPatch = ''
    patchShebangs hipamd

    # We're not on Windows so these are never installed to hipcc...
    substituteInPlace hipamd/CMakeLists.txt \
      --replace "install(PROGRAMS \''${HIPCC_BIN_DIR}/hipcc.bat DESTINATION bin)" "" \
      --replace "install(PROGRAMS \''${HIPCC_BIN_DIR}/hipconfig.bat DESTINATION bin)" ""

    substituteInPlace hipamd/src/hip_embed_pch.sh \
      --replace "\''$LLVM_DIR/bin/clang" "${rocmPackages_5.llvm.clang}/bin/clang"
  '';

  postInstall = lib.optionalString buildShared ''
    patchShebangs $out/bin

    # hipcc.bin and hipconfig.bin is mysteriously never installed
    cp -a ${rocmPackages_5.hipcc}/bin/{hipcc.bin,hipconfig.bin} $out/bin
  '' + lib.optionalString buildShared (lib.concatStrings (lib.forEach [
    "hipcc.bin" "hipconfig.bin" "hipcc.pl" "hipconfig.pl"
  ] (target: ''
    wrapProgram $out/bin/${target} ${lib.concatStringsSep " " wrapperArgs}
  ''))) + lib.optionalString buildShared ''
    # Just link rocminfo, it's easier
    ln -s ${rocmPackages_5.rocminfo}/bin/* $out/bin

    # These don't have the executable bit for some reason
    chmod +x $out/lib/{libamdhip64,libhiprtc-builtins,libhiprtc}.so.*-*
  '' + ''
    # Replace rocm-opencl-icd functionality
    mkdir -p $icd/etc/OpenCL/vendors
    echo "$out/lib/libamdocl64.so" > $icd/etc/OpenCL/vendors/amdocl64.icd
  '';

  passthru = {
    prefixName = "clr";

    tests = {
      # Tests requires the shared variant
      hip-tests = callPackage ./tests/hip-tests.nix {
        inherit stdenv commonNativeBuildInputs commonCMakeFlags rocmUpdateScript;
        testedPackage = rocmPackages_5.clr-variants.shared;
      };

      ocltst = callPackage ./tests/ocltst.nix { testedPackage = finalAttrs.finalPackage; };

      # Tests requires the shared variant
      opencl-example = callPackage ./tests/opencl-example.nix {
        testedPackage = rocmPackages_5.clr-variants.shared;
      };
    };

    impureTests = {
      hip-tests = callPackage ../impureTests.nix {
        testedPackage = rocmPackages_5.clr-variants.shared;
        testName = "hip-tests";
        isNested = true;
      };

      ocltst = callPackage ../impureTests.nix {
        testedPackage = finalAttrs.finalPackage;
        testName = "ocltst";
        isNested = true;
        isExecutable = true;
      };

      opencl-example = callPackage ../impureTests.nix {
        testedPackage = rocmPackages_5.clr-variants.shared;
        testName = "opencl-example";
        isNested = true;
      };
    };

    # All known and valid general GPU targets
    # We cannot use this for each ROCm library, as each defines their own supported targets
    # See: https://github.com/RadeonOpenCompute/ROCm/blob/77cbac4abab13046ee93d8b5bf410684caf91145/README.md#library-target-matrix
    gpuTargets = lib.forEach [
      "803"  "900"  "906"  "908"
      "90a"  "940"  "941"  "942"
      "1010" "1012" "1030" "1100"
      "1101" "1102"
    ] (target: "gfx${target}");

    updateScript = rocmUpdateScript {
      name = finalAttrs.pname;
      owner = finalAttrs.src.owner;
      repo = finalAttrs.src.repo;
      page = "tags?per_page=1";
      filter = ".[0].name | split(\"-\") | .[1]";
    };
  };

  meta = with lib; {
    description = "AMD Common Language Runtime for hipamd, opencl, and rocclr";
    homepage = "https://github.com/ROCm-Developer-Tools/clr";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ lovesegfault ] ++ teams.rocm.members;
    platforms = platforms.linux;
    broken = versions.minor finalAttrs.version != versions.minor rocmPackages_5.llvm.llvm.version;
  };
})
