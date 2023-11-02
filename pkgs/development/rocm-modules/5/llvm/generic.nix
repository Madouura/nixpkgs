{ lib
, fetchFromGitHub
, pkg-config
, cmake
, ninja
, git
, doxygen
, sphinx
, lit
, libxml2
, libxcrypt
, libedit
, libffi
, mpfr
, zlib
, ncurses
, python3Packages
, stdenv ? { }
, rocmPackages ? { }
, buildDocs ? true
, buildMan ? true
, buildTests ? true
, targetName ? "llvm"
, targetDir ? "llvm"
, targetProjects ? [ ]
, targetRuntimes ? [ ]
, llvmTargetsToBuild ? [ "NATIVE" ] # "NATIVE" resolves into x86 or aarch64 depending on stdenv
, extraPatches ? [ ]
, extraNativeBuildInputs ? [ ]
, extraBuildInputs ? [ ]
, extraCMakeFlags ? [ ]
, extraPostPatch ? ""
, checkTargets ? [(
  lib.optionalString buildTests (
    if targetDir == "runtimes"
    then "check-runtimes"
    else "check-all"
  )
)]
, extraPostInstall ? ""
, isLibCXX ? false
, hardeningDisable ? [ ]
, requiredSystemFeatures ? [ ]
, extraLicenses ? [ ]
, isBroken ? false
}:

let
  llvmNativeTarget =
    if stdenv.isx86_64 then "X86"
    else if stdenv.isAarch64 then "AArch64"
    else throw "Unsupported ROCm LLVM platform";
  inferNativeTarget = t: if t == "NATIVE" then llvmNativeTarget else t;
  llvmTargetsToBuild' = [ "AMDGPU" ] ++ builtins.map inferNativeTarget llvmTargetsToBuild;
in stdenv.mkDerivation (finalAttrs: {
  pname = "rocm-llvm-${targetName}";
  version = "5.7.1";

  outputs = [
    "out"
  ] ++ lib.optionals buildDocs [
    "doc"
  ] ++ lib.optionals buildMan [
    "man"
    "info" # Avoid `attribute 'info' missing` when using with wrapCC
  ];

  patches = extraPatches;

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "llvm-project";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-0+lJnDiMntxCYbZBCSWvHOcKXexFfEzRfb49QbfOmK8=";
  };

  nativeBuildInputs = [
    pkg-config
    cmake
    ninja
    git
    python3Packages.python
  ] ++ lib.optionals (buildDocs || buildMan) [
    doxygen
    sphinx
    python3Packages.recommonmark
  ] ++ lib.optionals (buildTests && (targetDir != "llvm")) [
    lit
  ] ++ extraNativeBuildInputs;

  buildInputs = [
    libxml2
    libxcrypt
    libedit
    libffi
    mpfr
  ] ++ extraBuildInputs;

  propagatedBuildInputs = lib.optionals (targetDir == "llvm") [
    zlib
    ncurses
  ];

  sourceRoot = "${finalAttrs.src.name}/${targetDir}";

  cmakeFlags = [
    "-DLLVM_TARGETS_TO_BUILD=${builtins.concatStringsSep ";" llvmTargetsToBuild'}"
  ] ++ lib.optionals (targetDir == "llvm" && targetProjects != [ ]) [
    "-DLLVM_ENABLE_PROJECTS=${lib.concatStringsSep ";" targetProjects}"
  ] ++ lib.optionals ((targetDir == "llvm" || targetDir == "runtimes") && targetRuntimes != [ ]) [
    "-DLLVM_ENABLE_RUNTIMES=${lib.concatStringsSep ";" targetRuntimes}"
  ] ++ lib.optionals (targetDir == "llvm") [
    "-DLLVM_INSTALL_UTILS=ON"
    "-DLLVM_INSTALL_GTEST=ON"
  ] ++ lib.optionals (buildDocs || buildMan) [
    "-DLLVM_INCLUDE_DOCS=ON"
    "-DLLVM_BUILD_DOCS=ON"
    # "-DLLVM_ENABLE_DOXYGEN=ON" Way too slow, only uses one core
    "-DLLVM_ENABLE_SPHINX=ON"
    "-DSPHINX_OUTPUT_HTML=ON"
    "-DSPHINX_OUTPUT_MAN=ON"
    "-DSPHINX_WARNINGS_AS_ERRORS=OFF"
  ] ++ lib.optionals buildTests [
    "-DLLVM_INCLUDE_TESTS=ON"
    "-DLLVM_BUILD_TESTS=ON"
    "-DLLVM_EXTERNAL_LIT=${lit}/bin/.lit-wrapped"
  ] ++ extraCMakeFlags;

  postPatch = lib.optionalString (targetDir == "llvm") ''
    patchShebangs lib/OffloadArch/make_generated_offload_arch_h.sh
  '' + lib.optionalString (buildTests && targetDir == "llvm") ''
    # FileSystem permissions tests fail with various special bits
    rm test/tools/llvm-objcopy/ELF/mirror-permissions-unix.test
    rm unittests/Support/Path.cpp

    substituteInPlace unittests/Support/CMakeLists.txt \
      --replace "Path.cpp" ""
  '' + extraPostPatch;

  doCheck = buildTests;
  checkTarget = lib.concatStringsSep " " checkTargets;

  postInstall = lib.optionalString buildMan ''
    mkdir -p $info
  '' + extraPostInstall;

  passthru = {
    isLLVM = targetDir == "llvm" || isLibCXX;
    isClang = targetDir == "clang" || builtins.elem "clang" targetProjects;
    cxxabi = lib.optionalAttrs isLibCXX rocmPackages.llvm.libcxxabi;
    libName = lib.optionalString isLibCXX "c++abi";

    updateScript = rocmPackages.util.rocmUpdateScript {
      name = finalAttrs.pname;
      owner = finalAttrs.src.owner;
      repo = finalAttrs.src.repo;
    };
  };

  inherit hardeningDisable requiredSystemFeatures;

  meta = with lib; {
    description = "ROCm fork of the LLVM compiler infrastructure";
    homepage = "https://github.com/RadeonOpenCompute/llvm-project";
    license = with licenses; [ ncsa ] ++ extraLicenses;
    maintainers = with maintainers; [ acowley lovesegfault ] ++ teams.rocm.members;
    platforms = platforms.linux;

    broken =
      stdenv == { } ||
      rocmPackages == { } ||
      isBroken;
  };
})
