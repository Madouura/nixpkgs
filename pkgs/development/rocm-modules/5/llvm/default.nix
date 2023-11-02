{ stdenv
, callPackage
, wrapBintoolsWith
, overrideCC
, rocmPackages ? { }
}:

let
  ## Stage 1 ##
  # Helpers
  rCallPackage = path: stdenvOverride: attrs:
    callPackage path ({ inherit rocmPackages; stdenv = stdenvOverride; } // attrs);

  # Runtimes
  runtimes = rCallPackage ./stage-1/runtimes.nix stdenv { };

  ## Stage 2 ##
  # Helpers
  bintools-unwrapped = rCallPackage ./stage-2/bintools-unwrapped.nix stdenv { };
  rStdenv = rCallPackage ./stage-2/rstdenv.nix stdenv { inherit runtimes; };

  # Runtimes
  libc = rCallPackage ./stage-2/libc.nix rStdenv { };

  ## Stage 3 ##
  # Helpers
  clang = rCallPackage ./stage-3/clang.nix stdenv { };
  clangWithoutWarnings = clang.override { disableWarnings = true; };
  clangWithoutLLD = clang.override { useLLD = false; };
  clangWithLibC = clang.override { useLibC = true; };
  clangWithLibCXX = clang.override { useLibCXX = true; };
  clangWithoutLibUnwind = clang.override { useLibUnwind = false; };
  clangWithoutCompilerRt = clang.override { useCompilerRt = false; };
  rocmClangStdenv = overrideCC stdenv clang;
in {
  inherit
    libc
    clang
    clangWithoutWarnings
    clangWithoutLLD
    clangWithLibC
    clangWithLibCXX
    clangWithoutLibUnwind
    clangWithoutCompilerRt
    rocmClangStdenv;

  ## Stage 1 ##
  # Projects
  llvm = rCallPackage ./stage-1/llvm.nix stdenv { };
  clang-unwrapped = rCallPackage ./stage-1/clang-unwrapped.nix stdenv { };
  lld = rCallPackage ./stage-1/lld.nix stdenv { };

  ## Stage 2 ##
  # Helpers
  bintools = wrapBintoolsWith { bintools = bintools-unwrapped; };
  bintoolsWithLibC = wrapBintoolsWith { inherit libc; bintools = bintools-unwrapped; };

  # Runtimes
  libunwind = rCallPackage ./stage-2/libunwind.nix rStdenv { };
  libcxxabi = rCallPackage ./stage-2/libcxxabi.nix rStdenv { };
  libcxx = rCallPackage ./stage-2/libcxx.nix rStdenv { };
  compiler-rt = rCallPackage ./stage-2/compiler-rt.nix rStdenv { };

  ## Stage 3 ##
  # Helpers
  rocmClangStdenvWithoutWarnings = overrideCC stdenv clangWithoutWarnings;
  rocmClangStdenvWithoutLLD = overrideCC stdenv clangWithoutLLD;
  rocmClangStdenvWithLibC = overrideCC stdenv clangWithLibC;
  rocmClangStdenvWithLibCXX = overrideCC stdenv clangWithLibCXX;
  rocmClangStdenvWithoutLibUnwind = overrideCC stdenv clangWithoutLibUnwind;
  rocmClangStdenvWithoutCompilerRt = overrideCC stdenv clangWithoutCompilerRt;

  # Projects
  clang-tools-extra = rCallPackage ./stage-3/clang-tools-extra.nix rocmClangStdenv { };
  libclc = rCallPackage ./stage-3/libclc.nix rocmClangStdenv { };
  lldb = rCallPackage ./stage-3/lldb.nix rocmClangStdenv { };
  mlir = rCallPackage ./stage-3/mlir.nix rocmClangStdenv { };
  polly = rCallPackage ./stage-3/polly.nix rocmClangStdenv { };
  flang = rCallPackage ./stage-3/flang.nix rocmClangStdenv { };
  openmp = rCallPackage ./stage-3/openmp.nix rocmClangStdenv { };

  # Runtimes
  pstl = rCallPackage ./stage-3/pstl.nix rocmClangStdenv { };
}
