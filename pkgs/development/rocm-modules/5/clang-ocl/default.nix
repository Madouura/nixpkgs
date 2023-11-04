{ lib
, fetchFromGitHub
, rocmPackages ? { }
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
    repo = "clang-ocl";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-uMSvcVJj+me2E+7FsXZ4l4hTcK6uKEegXpkHGcuist0=";
  };

  buildInputs = with rocmPackages; [ rocm-device-libs ];
  passthru.prefixName = "clang-ocl";

  meta = with lib; oldAttrs.meta // {
    description = "OpenCL compilation with clang compiler";
    homepage = "https://github.com/RadeonOpenCompute/clang-ocl";
    license = with licenses; [ mit ];
  };
})
