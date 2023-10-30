{ lib
, stdenv
, fetchFromGitHub
, commonNativeBuildInputs
, commonCMakeFlags
, rocmUpdateScript
, rocmPackages_5
, xxd
, libxml2
, libdrm
, libelf
, numactl
, valgrind
, buildShared ? true
, imageSupport ? true
}:

stdenv.mkDerivation (finalAttrs: {
  pname = finalAttrs.passthru.prefixName + (
    if buildShared
    then "-shared"
    else "-static"
  ) + (
    if imageSupport
    then "-image"
    else ""
  );

  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCR-Runtime";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-D7Ahan5cxDhqPtV5iDDNys0A4FlxQ9oVRa2EeMoY5Qk=";
  };

  sourceRoot = "${finalAttrs.src.name}/src";
  nativeBuildInputs = [ xxd ] ++ commonNativeBuildInputs;

  buildInputs = with rocmPackages_5; [
    rocm-thunk
    libxml2
    libdrm
    libelf
    numactl
    valgrind
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED_LIBS" buildShared)
    (lib.cmakeBool "IMAGE_SUPPORT" imageSupport)
  ] ++ commonCMakeFlags;

  postPatch = ''
    patchShebangs core 
  '' + lib.optionalString imageSupport ''
    patchShebangs image

    # We compile clang before rocm-device-libs, so patch it in afterwards
    # Replace code object version: https://github.com/RadeonOpenCompute/ROCR-Runtime/issues/166 (TODO: Remove on LLVM update?)
    substituteInPlace image/blit_src/CMakeLists.txt \
      --replace "-cl-denorms-are-zero" "--rocm-device-lib-path=${rocmPackages_5.rocm-device-libs}/amdgcn/bitcode -cl-denorms-are-zero" \
      --replace "-mcode-object-version=4" "-mcode-object-version=5"
  '';

  passthru = {
    prefixName = "rocm-runtime";

    updateScript = rocmUpdateScript {
      name = finalAttrs.pname;
      owner = finalAttrs.src.owner;
      repo = finalAttrs.src.repo;
    };
  };

  meta = with lib; {
    description = "Platform runtime for ROCm";
    homepage = "https://github.com/RadeonOpenCompute/ROCR-Runtime";
    license = with licenses; [ ncsa ];
    maintainers = with maintainers; [ lovesegfault ] ++ teams.rocm.members;
    platforms = platforms.linux;
    broken = versions.minor finalAttrs.version != versions.minor rocmPackages_5.llvm.llvm.version;
  };
})
