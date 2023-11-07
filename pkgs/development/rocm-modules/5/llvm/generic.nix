{ lib
, stdenv
, fetchFromGitHub
, rocmPackages
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
, libpfm
, mpfr
, zlib
, ncurses
, python3Packages
, buildDocs ? true
, buildMan ? true
, buildTests ? true
, targetName ? "llvm"
, targetDir ? "llvm"
, targetProjects ? [ ]
, targetRuntimes ? [ ]
# "NATIVE" resolves into x86 or aarch64 depending on stdenv
, llvmTargetsToBuild ? [ "NATIVE" ]
}:

let
  # Keeping in case we one day get ARM support
  llvmNativeTarget =
    if stdenv.isx86_64 then "X86"
    else if stdenv.isAarch64 then "AArch64"
    else throw "Unsupported ROCm LLVM platform";

  inferNativeTarget = t: if t == "NATIVE" then llvmNativeTarget else t;
  llvmTargetsToBuild' = [ "AMDGPU" ] ++ builtins.map inferNativeTarget llvmTargetsToBuild;

  python =
    if buildTests
    then python3Packages.python.withPackages (p: with p; [ psutil pygments pyyaml ])
    else python3Packages.python;
in stdenv.mkDerivation (finalAttrs: {
  pname = "rocm-llvm-${targetName}";
  version = "5.7.1";

  outputs = [
    "out"
  ] ++ lib.optionals buildDocs [
    "doc"
  ] ++ lib.optionals buildMan [
    "man"
  ];

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "llvm-project";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-0+lJnDiMntxCYbZBCSWvHOcKXexFfEzRfb49QbfOmK8=";
  };

  sourceRoot = "${finalAttrs.src.name}/${targetDir}";

  nativeBuildInputs = [
    pkg-config
    cmake
    ninja
    git
    python
  ] ++ lib.optionals (buildDocs || buildMan) [
    doxygen
    sphinx
    python3Packages.recommonmark
  ] ++ lib.optionals buildTests [
    lit
  ];

  buildInputs = [
    libxml2
    libxcrypt
    libedit
    libffi
    libpfm
    mpfr
  ];

  propagatedBuildInputs = [
    zlib
    ncurses
    python3Packages.python
    python3Packages.pygments
    python3Packages.pyyaml
  ];

  cmakeFlags = [
    (lib.cmakeBool "LLVM_INCLUDE_DOCS" (buildDocs || buildMan))
    (lib.cmakeBool "LLVM_BUILD_DOCS" (buildDocs || buildMan))
    # Way too slow, only uses one core
    # (lib.cmakeBool "LLVM_ENABLE_DOXYGEN" (buildDocs || buildMan))
    (lib.cmakeBool "LLVM_ENABLE_SPHINX" (buildDocs || buildMan))
    (lib.cmakeBool "SPHINX_OUTPUT_HTML" buildDocs)
    (lib.cmakeBool "SPHINX_OUTPUT_MAN" buildMan)
    (lib.cmakeBool "SPHINX_WARNINGS_AS_ERRORS" false)
    (lib.cmakeBool "LLVM_INCLUDE_TESTS" buildTests)
    (lib.cmakeBool "LLVM_BUILD_TESTS" buildTests)
    (lib.cmakeFeature "LLVM_TARGETS_TO_BUILD" (lib.concatStringsSep ";" llvmTargetsToBuild'))
  ] ++ lib.optionals (targetProjects != [ ] && targetDir == "llvm") [
    (lib.cmakeFeature "LLVM_ENABLE_PROJECTS" (lib.concatStringsSep ";" targetProjects))
  ] ++ lib.optionals (targetRuntimes != [ ] && (targetDir == "llvm" || targetDir == "runtimes")) [
    (lib.cmakeFeature "LLVM_ENABLE_RUNTIMES" (lib.concatStringsSep ";" targetRuntimes))
  ] ++ lib.optionals buildTests [
    (lib.cmakeFeature "LLVM_EXTERNAL_LIT" "${lit}/bin/.lit-wrapped")
  ];

  doCheck = buildTests;

  checkTarget = lib.optionalString buildTests (
    if targetDir == "llvm"
    then "check-all"
    else "check-${targetDir}"
  );

  passthru = {
    pythonPackages = python3Packages;

    updateScript = rocmPackages.util.rocmUpdateScript {
      name = finalAttrs.pname;
      owner = finalAttrs.src.owner;
      repo = finalAttrs.src.repo;
    };
  };

  meta = with lib; {
    description = "ROCm fork of the LLVM compiler infrastructure";
    homepage = "https://github.com/RadeonOpenCompute/llvm-project";
    changelog = "https://rocm.docs.amd.com/en/docs-${finalAttrs.version}/release.html";
    license = with licenses; [ ncsa ];

    maintainers = with maintainers; [
      acowley
      lovesegfault
    ] ++ teams.rocm.members;

    # ROCm is only really supported on `x86_64-linux`
    # https://github.com/RadeonOpenCompute/ROCm/issues/1831#issuecomment-1278205344
    platforms = [ "x86_64-linux" ];
  };
})
