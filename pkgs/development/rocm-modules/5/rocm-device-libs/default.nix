{ lib
, fetchFromGitHub
, libxml2
, stdenv ? { }
, rocmMkDerivation ? { }
, ...
}:

{ buildTests ? true
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
  inherit buildTests;
} (finalAttrs: oldAttrs: {
  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCm-Device-Libs";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-ARxs/yqyVoIUWliJkINzitumF+64/5u3fbB0tHB5hPU=";
  };

  patches = [
    ./0000-fix-cmake-objects.patch
    ./0001-skip-gfx700-atan-atan2pi-tests.patch
  ];

  buildInputs = [ libxml2 ];

  cmakeFlags = oldAttrs.cmakeFlags ++ [
    (lib.cmakeFeature "LLVM_TARGETS_TO_BUILD" (lib.concatStringsSep ";" llvmTargetsToBuild'))
  ];

  passthru.prefixName = "rocm-device-libs";

  meta = with lib; oldAttrs.meta // {
    description = "Set of AMD-specific device-side language runtime libraries";
    homepage = "https://github.com/RadeonOpenCompute/ROCm-Device-Libs";
    license = licenses.ncsa;
    maintainers = with maintainers; oldAttrs.meta.maintainers ++ [ lovesegfault ];
  };
})
