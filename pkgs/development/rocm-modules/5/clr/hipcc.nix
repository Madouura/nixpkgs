{ lib
, fetchFromGitHub
, lsb-release
, rocmMkDerivation ? { }
, ...
}:

{ }:

rocmMkDerivation { } (finalAttrs: oldAttrs: {
  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "HIPCC";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-lJX6nF1V4YmK5ai7jivXlRnG3doIOf6X9CWLHVdRuVg=";
  };

  postPatch = ''
    substituteInPlace src/hipBin_amd.h \
      --replace "/usr/bin/lsb_release" "${lsb-release}/bin/lsb_release"
  '';

  postInstall = ''
    rm -rf $out/hip/bin
    ln -s $out/bin $out/hip/bin
  '';

  passthru.prefixName = "hipcc";

  meta = with lib; oldAttrs.meta // {
    description = "Compiler driver utility that calls clang or nvcc";
    homepage = "https://github.com/ROCm-Developer-Tools/HIPCC";
    license = with licenses; [ mit ];
    maintainers = with maintainers; oldAttrs.meta.maintainers ++ [ lovesegfault ];
  };
})
