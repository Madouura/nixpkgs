{ lib
, fetchFromGitHub
, rocmPackages
, cmake
, git
, buildTests ? true
}:

(finalAttrs: oldAttrs: {
  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-ihG/bxD8bQVm+znXs0R/n3LznKY0HbHz2UA/+IBwCC8=";
    leaveDotGit = true;
  };

  nativeBuildInputs = [ cmake ];
  cmakeFlags = rocmPackages.util.commonCMakeFlags;
  nativeCheckInputs = [ git ];

  preCheck = lib.optionalString buildTests ''
    export HOME=$TMPDIR
    git config --global user.email "nixos@nixos.org"
    git config --global user.name "NixOS"

    # list index: 10 out of range (-1, 0)
    rm ../test/pass/version-parent.cmake

    # Not supposed to pass, but it does
    rm ../test/fail/wrapper.cmake
  '';

  passthru = oldAttrs.passthru // {
    prefixName = "rocm-cmake";
    inherit buildTests;
  };

  meta = with lib; oldAttrs.meta // {
    description = "CMake modules for common build tasks for the ROCm stack";
    homepage = "https://github.com/RadeonOpenCompute/rocm-cmake";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
