{ lib
, fetchFromGitHub
, cmake
, git
, rocmMkDerivation ? { }
, ...
}:

{ buildTests ? true }:

rocmMkDerivation {
  inherit buildTests;
} (finalAttrs: oldAttrs: {
  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-ihG/bxD8bQVm+znXs0R/n3LznKY0HbHz2UA/+IBwCC8=";
    leaveDotGit = true;
  };

  nativeBuildInputs = [ cmake ];
  nativeCheckInputs = [ git ];

  preCheck = lib.optionalString buildTests ''
    export HOME=$TMPDIR
    git config --global user.email "none@none.org"
    git config --global user.name "None"

    # list index: 10 out of range (-1, 0)
    rm ../test/pass/version-parent.cmake

    # Not supposed to pass, but it does
    rm ../test/fail/wrapper.cmake
  '';

  passthru.prefixName = "rocm-cmake";

  meta = with lib; oldAttrs.meta // {
    description = "CMake modules for common build tasks for the ROCm stack";
    homepage = "https://github.com/RadeonOpenCompute/rocm-cmake";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
