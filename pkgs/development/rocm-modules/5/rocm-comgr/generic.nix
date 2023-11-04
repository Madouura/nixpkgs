{ lib
, fetchFromGitHub
, libxml2
, stdenv ? { }
, rocmPackages ? { }
, rocmMkDerivation ? { }
}:

{ buildShared ? true
, buildTests ? true
, llvmTargetsToBuild ? [ "NATIVE" ] # "NATIVE" resolves into x86 or aarch64 depending on stdenv
}:

let
  llvmNativeTarget =
    if stdenv.isx86_64 then "X86"
    else if stdenv.isAarch64 then "AArch64"
    else throw "Unsupported ROCm LLVM platform";

  inferNativeTarget = t: if t == "NATIVE" then llvmNativeTarget else t;
  llvmTargetsToBuild' = [ "AMDGPU" ] ++ builtins.map inferNativeTarget llvmTargetsToBuild;
in rocmMkDerivation {
  inherit buildShared buildTests;
} (finalAttrs: oldAttrs: {
  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCm-CompilerSupport";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-QB3G0V92UTW67hD6+zSuExN1+eMT820iYSlMyZeWSFw=";
  };

  sourceRoot = "${finalAttrs.src.name}/lib/comgr";

  buildInputs = with rocmPackages; [
    rocm-device-libs
    libxml2
  ];

  cmakeFlags = oldAttrs.cmakeFlags ++ [
    (lib.cmakeFeature "LLVM_TARGETS_TO_BUILD" (lib.concatStringsSep ";" llvmTargetsToBuild'))
    (lib.cmakeBool "COMGR_BUILD_SHARED_LIBS" buildShared)
  ];

  passthru = oldAttrs.passthru // {
    prefixName = "rocm-comgr";
    prefixNameSuffix = "-variants";
  };

  meta = with lib; oldAttrs.meta // {
    description = "APIs for compiling and inspecting AMDGPU code objects";
    homepage = "https://github.com/RadeonOpenCompute/ROCm-CompilerSupport";
    license = licenses.ncsa;
    maintainers = with maintainers; oldAttrs.meta.maintainers ++ [ lovesegfault ];
  };
})
