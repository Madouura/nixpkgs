{ lib
, fetchFromGitHub
, xxd
, libxml2
, libdrm
, libelf
, numactl
, valgrind
, rocmPackages ? { }
, rocmMkDerivation ? { }
, ...
}:

{ buildShared ? true
, imageSupport ? true
}:

rocmMkDerivation {
  inherit buildShared;
} (finalAttrs: oldAttrs: {
  pname =
    oldAttrs.pname
  + (
    if imageSupport
    then "-image"
    else "-default"
  );

  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCR-Runtime";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-D7Ahan5cxDhqPtV5iDDNys0A4FlxQ9oVRa2EeMoY5Qk=";
  };

  sourceRoot = "${finalAttrs.src.name}/src";
  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ xxd ];

  buildInputs = with rocmPackages; [
    rocm-thunk
    libxml2
    libdrm
    libelf
    numactl
    valgrind
  ];

  cmakeFlags = oldAttrs.cmakeFlags ++ [
    (lib.cmakeBool "BUILD_SHARED_LIBS" buildShared)
    (lib.cmakeBool "IMAGE_SUPPORT" imageSupport)
  ];

  postPatch = ''
    patchShebangs core 
  '' + lib.optionalString imageSupport ''
    patchShebangs image

    # We compile clang before rocm-device-libs, so patch it in afterwards
    # Replace code object version: https://github.com/RadeonOpenCompute/ROCR-Runtime/issues/166 (TODO: Remove on LLVM update?)
    substituteInPlace image/blit_src/CMakeLists.txt \
      --replace "-cl-denorms-are-zero" "--rocm-device-lib-path=${rocmPackages.rocm-device-libs}/amdgcn/bitcode -cl-denorms-are-zero" \
      --replace "-mcode-object-version=4" "-mcode-object-version=5"
  '';

  passthru = oldAttrs.passthru // {
    prefixName = "rocm-runtime";
    prefixNameSuffix = "-variants";
  };

  meta = with lib; oldAttrs.meta // {
    description = "Platform runtime for ROCm";
    homepage = "https://github.com/RadeonOpenCompute/ROCR-Runtime";
    license = with licenses; [ ncsa ];
    maintainers = with maintainers; oldAttrs.meta.maintainers ++ [ lovesegfault ];
  };
})
