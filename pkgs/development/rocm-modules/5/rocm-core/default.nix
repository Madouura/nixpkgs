{ lib
, fetchFromGitHub
, cmake
, rocmPackages ? { }
, rocmMkDerivation ? { }
, ...
}:

{ }:

rocmMkDerivation { } (finalAttrs: oldAttrs: {
  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-core";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-jFAHLqf/AR27Nbuq8aypWiKqApNcTgG5LWESVjVCKIg=";
  };

  nativeBuildInputs = [ cmake ];

  cmakeFlags = oldAttrs.cmakeFlags ++ [
    (lib.cmakeFeature "ROCM_VERSION" finalAttrs.version)
    (lib.cmakeFeature "CPACK_PACKAGING_INSTALL_PREFIX" (placeholder "out"))
  ];

  postPatch = ''
    substituteInPlace rocmmod.in \
      --replace "@CPACK_PACKAGING_INSTALL_PREFIX@/llvm/bin" \
        "${rocmPackages.llvm.clang.cc}/bin" \
      --replace "@CPACK_PACKAGING_INSTALL_PREFIX@/llvm/share/man1" \
        "${lib.getMan rocmPackages.llvm.llvm}/share/man/man1:${lib.getMan rocmPackages.llvm.clang-unwrapped}/share/man/man1"
  '';

  passthru = oldAttrs.passthru // {
    prefixName = "rocm-core";

    updateScript = rocmPackages.util.rocmUpdateScript {
      name = finalAttrs.passthru.prefixName;
      owner = finalAttrs.src.owner;
      repo = finalAttrs.src.repo;
      page = "tags?per_page=1";
      filter = ".[0].name | split(\"-\") | .[1]";
    };
  };

  meta = with lib; oldAttrs.meta // {
    description = "Utility for getting the ROCm release version";
    homepage = "https://github.com/RadeonOpenCompute/rocm-core";
    license = with licenses; [ mit ];
    platforms = platforms.unix;
  };
})
