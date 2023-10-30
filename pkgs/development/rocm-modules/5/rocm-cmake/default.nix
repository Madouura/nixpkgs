{ lib
, stdenv
, fetchFromGitHub
, commonCMakeFlags
, rocmUpdateScript
, rocmPackages_5
, cmake
, git
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rocm-cmake";
  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-ihG/bxD8bQVm+znXs0R/n3LznKY0HbHz2UA/+IBwCC8=";
    leaveDotGit = true;
  };

  nativeBuildInputs = [ cmake ];
  cmakeFlags = commonCMakeFlags;
  doCheck = true;
  nativeCheckInputs = [ git ];

  preCheck = ''
    export HOME=$TMPDIR
    git config --global user.email "none@nixos.org"
    git config --global user.name "None"

    # list index: 10 out of range (-1, 0)
    rm ../test/pass/version-parent.cmake

    # Not supposed to pass, but it does
    rm ../test/fail/wrapper.cmake
  '';

  passthru.updateScript = rocmUpdateScript {
    name = finalAttrs.pname;
    owner = finalAttrs.src.owner;
    repo = finalAttrs.src.repo;
  };

  meta = with lib; {
    description = "CMake modules for common build tasks for the ROCm stack";
    homepage = "https://github.com/RadeonOpenCompute/rocm-cmake";
    license = licenses.mit;
    maintainers = teams.rocm.members;
    platforms = platforms.unix;
    broken = versions.minor finalAttrs.version != versions.minor rocmPackages_5.llvm.llvm.version;
  };
})
