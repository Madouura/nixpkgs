{ lib
, stdenv
, fetchFromGitHub
, commonNativeBuildInputs
, commonCMakeFlags
, rocmUpdateScript
, rocmPackages_5
, libxml2
, llvmTargetsToBuild ? [ "NATIVE" ] # "NATIVE" resolves into x86 or aarch64 depending on stdenv
, buildShared ? true
}:

let
  llvmNativeTarget =
    if stdenv.isx86_64 then "X86"
    else if stdenv.isAarch64 then "AArch64"
    else throw "Unsupported ROCm LLVM platform";

  inferNativeTarget = t: if t == "NATIVE" then llvmNativeTarget else t;
  llvmTargetsToBuild' = [ "AMDGPU" ] ++ builtins.map inferNativeTarget llvmTargetsToBuild;
in stdenv.mkDerivation (finalAttrs: {
  pname = finalAttrs.passthru.prefixName + (
    if buildShared
    then "-shared"
    else "-static"
  );

  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCm-CompilerSupport";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-QB3G0V92UTW67hD6+zSuExN1+eMT820iYSlMyZeWSFw=";
  };

  sourceRoot = "${finalAttrs.src.name}/lib/comgr";
  nativeBuildInputs = commonNativeBuildInputs;

  buildInputs = with rocmPackages_5; [
    rocm-device-libs
    libxml2
  ];

  cmakeFlags = [
    (lib.cmakeFeature "LLVM_TARGETS_TO_BUILD" (lib.concatStringsSep ";" llvmTargetsToBuild'))
    (lib.cmakeBool "COMGR_BUILD_SHARED_LIBS" buildShared)
  ] ++ commonCMakeFlags;

  doCheck = true;

  passthru = {
    prefixName = "rocm-comgr";

    updateScript = rocmUpdateScript {
      name = finalAttrs.pname;
      owner = finalAttrs.src.owner;
      repo = finalAttrs.src.repo;
    };
  };

  meta = with lib; {
    description = "APIs for compiling and inspecting AMDGPU code objects";
    homepage = "https://github.com/RadeonOpenCompute/ROCm-CompilerSupport";
    license = licenses.ncsa;
    maintainers = with maintainers; [ lovesegfault ] ++ teams.rocm.members;
    platforms = platforms.linux;
    broken = versions.minor finalAttrs.version != versions.minor rocmPackages_5.llvm.llvm.version;
  };
})
