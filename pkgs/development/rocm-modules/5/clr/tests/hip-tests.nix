{ lib
, fetchFromGitHub
, git
, vulkan-loader
, vulkan-headers
, shaderc
, rocmPackages ? { }
, rocmMkDerivation ? { }
, ...
}:

{ testedPackage ? { } }:

rocmMkDerivation {
  buildTests = true;
} (finalAttrs: oldAttrs: {
  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "hip-tests";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-P5qTF4l67YE2QwGQXnyVU5B9lhqIlnXbSck4dY7dcoU=";
    leaveDotGit = true;
  };

  sourceRoot = "${finalAttrs.src.name}/catch";

  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
    testedPackage
    git
    vulkan-loader
    vulkan-headers
    shaderc
  ];

  cmakeFlags = oldAttrs.cmakeFlags ++ [
    (lib.cmakeFeature "ROCM_PATH" "${testedPackage}")
    (lib.cmakeFeature "HIP_PATH" "${testedPackage}")
    (lib.cmakeFeature "HIP_PLATFORM" "amd")
    # `error: use of undeclared identifier 'launchRTCKernel'`
    (lib.cmakeBool "RTC_TESTING" false)
  ];

  ninjaFlags = [ "build_tests" ];

  postPatch = ''
    # `clang++: error: cannot specify -o when generating multiple output files`
    substituteInPlace CMakeLists.txt \
      --replace "add_subdirectory(multiproc \''${CATCH_BUILD_DIR}/multiproc)" ""

    # This set of unit tests is device-specific (My gfx1030 isn't included)
    # Also `clang++: error: cannot specify -o when generating multiple output files`
    # https://github.com/ROCm-Developer-Tools/hip-tests/blob/9cf8b321af4b705102bc2ff00501d694064ff71c/catch/unit/deviceLib/CMakeLists.txt#L90
    substituteInPlace unit/CMakeLists.txt \
      --replace "add_subdirectory(deviceLib)" "" \
      --replace "add_subdirectory(graph)" "" \
      --replace "add_subdirectory(callback)" "" \
      --replace "add_subdirectory(cooperativeGrps)" "" # This one makes my graphics driver lock up, might be my bcachefs kernel though...
  '';

  passthru = oldAttrs.passthru // {
    prefixName = "hip-tests";

    updateScript = rocmPackages.util.rocmUpdateScript {
      name = finalAttrs.pname;
      owner = finalAttrs.src.owner;
      repo = finalAttrs.src.repo;
      page = "tags?per_page=1";
      filter = ".[0].name | split(\"-\") | .[1]";
    };
  };

  # `error in backend: Cannot select: 0x93d8eb0: i64 = FrameIndex<0>`
  hardeningDisable = [ "stackprotector" ];

  meta = with lib; oldAttrs.meta // {
    description = "HIP unit tests";
    homepage = "https://github.com/ROCm-Developer-Tools/hip-tests";
    license = with licenses; [ mit ];
  };
})
