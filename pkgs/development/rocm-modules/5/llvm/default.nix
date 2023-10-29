{ stdenv
, callPackage
, rocmUpdateScript
, wrapBintoolsWith
, overrideCC
, rocm-device-libs
, rocm-runtime
, rocm-thunk
, clr
}:

let
  ## Stage 1 ##
  # Projects
  llvm = callPackage ./stage-1/llvm.nix { inherit rocmUpdateScript; };
  clang-unwrapped = callPackage ./stage-1/clang-unwrapped.nix { inherit rocmUpdateScript llvm; };
  lld = callPackage ./stage-1/lld.nix { inherit rocmUpdateScript llvm; };

  # Runtimes
  runtimes = callPackage ./stage-1/runtimes.nix { inherit rocmUpdateScript llvm; };

  ## Stage 2 ##
  # Helpers
  bintools-unwrapped = callPackage ./stage-2/bintools-unwrapped.nix { inherit llvm lld; };
  bintools = wrapBintoolsWith { bintools = bintools-unwrapped; };
  bintoolsWithLibC = wrapBintoolsWith { inherit libc; bintools = bintools-unwrapped; };     
  rStdenv = callPackage ./stage-2/rstdenv.nix { inherit llvm clang-unwrapped lld runtimes bintools; };

  # Runtimes
  libc = callPackage ./stage-2/libc.nix { inherit rocmUpdateScript; stdenv = rStdenv; };
in rec {
  inherit
  llvm
  clang-unwrapped
  lld
  bintools
  bintoolsWithLibC
  libc;

  libunwind = callPackage ./stage-2/libunwind.nix { inherit rocmUpdateScript; stdenv = rStdenv; };
  libcxxabi = callPackage ./stage-2/libcxxabi.nix { inherit rocmUpdateScript; stdenv = rStdenv; };
  libcxx = callPackage ./stage-2/libcxx.nix { inherit rocmUpdateScript libcxxabi; stdenv = rStdenv; };
  compiler-rt = callPackage ./stage-2/compiler-rt.nix { inherit rocmUpdateScript llvm; stdenv = rStdenv; };

  ## Stage 3 ##
  # Helpers
  clang = clangWithWarnings.override { disableWarnings = true; };
  clangWithWarnings = callPackage ./stage-3/clang.nix { inherit llvm lld clang-unwrapped bintools bintoolsWithLibC libc libunwind libcxxabi libcxx compiler-rt; };
  clangWithoutLLD = clangWithWarnings.override { useLLD = false; };
  clangWithLibC = clangWithWarnings.override { useLibC = true; };
  clangWithLibCXX = clangWithWarnings.override { useLibCXX = true; };
  clangWithoutLibUnwind = clangWithWarnings.override { useLibUnwind = false; };
  clangWithoutCompilerRt = clangWithWarnings.override { useCompilerRt = false; };
  rocmClangStdenv = overrideCC stdenv clang;
  rocmClangStdenvWithWarnings = overrideCC stdenv clangWithWarnings;
  rocmClangStdenvWithoutLLD = overrideCC stdenv clangWithoutLLD;
  rocmClangStdenvWithLibC = overrideCC stdenv clangWithLibC;
  rocmClangStdenvWithLibCXX = overrideCC stdenv clangWithLibCXX;
  rocmClangStdenvWithoutLibUnwind = overrideCC stdenv clangWithoutLibUnwind;
  rocmClangStdenvWithoutCompilerRt = overrideCC stdenv clangWithoutCompilerRt;

  # Projects
  clang-tools-extra = callPackage ./stage-3/clang-tools-extra.nix { inherit rocmUpdateScript llvm clang-unwrapped; stdenv = rocmClangStdenv; };
  libclc = callPackage ./stage-3/libclc.nix { inherit rocmUpdateScript llvm clang; stdenv = rocmClangStdenv; };
  lldb = callPackage ./stage-3/lldb.nix { inherit rocmUpdateScript clang; stdenv = rocmClangStdenv; };
  mlir = callPackage ./stage-3/mlir.nix { inherit rocmUpdateScript clr; stdenv = rocmClangStdenv; };
  polly = callPackage ./stage-3/polly.nix { inherit rocmUpdateScript; stdenv = rocmClangStdenv; };
  flang = callPackage ./stage-3/flang.nix { inherit rocmUpdateScript clang-unwrapped mlir; stdenv = rocmClangStdenv; };
  openmp = callPackage ./stage-3/openmp.nix { inherit rocmUpdateScript llvm clang-unwrapped clang rocm-device-libs rocm-runtime rocm-thunk; stdenv = rocmClangStdenv; };

  # Runtimes
  pstl = callPackage ./stage-3/pstl.nix { inherit rocmUpdateScript; stdenv = rocmClangStdenv; };
}
