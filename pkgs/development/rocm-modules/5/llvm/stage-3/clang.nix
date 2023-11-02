{ lib
, wrapCCWith
, symlinkJoin
, stdenv ? { }
, rocmPackages ? { }
, useLLD ? true
, useLibC ? false
, useLibCXX ? false
, useLibUnwind ? true
, useCompilerRt ? true
, disableWarnings ? false
}:

let
  cc = let
    # Mimic a monolithic install
    rocm-llvm-clang-joined = symlinkJoin {
      name = "rocm-llvm-clang-joined";

      paths = with rocmPackages.llvm; [
        llvm
        clang-unwrapped
      ] ++ lib.optionals useLLD [
        lld
      ] ++ lib.optionals useLibC [
        libc
      ] ++ lib.optionals useLibCXX [
        libcxxabi
        libcxx
      ] ++ lib.optionals useLibUnwind [
        libunwind
      ] ++ lib.optionals useCompilerRt [
        compiler-rt
      ];

      postBuild = with rocmPackages.llvm; ''
        clang_version=$(${clang-unwrapped}/bin/clang -v 2>&1 | grep "clang version " | grep -E -o "[0-9.-]+")
        clang_dir="$out/lib/clang/$clang_version"
        ln -sf $out/include/* $clang_dir/include
        ln -s $out/lib $clang_dir
      '' + lib.optionalString useLibUnwind ''
        ln -sf ${clang-unwrapped}/lib/clang/$clang_version/include/unwind.h $clang_dir/include/unwind.h
      '';
    };
  in stdenv.mkDerivation (finalAttrs: {
    pname = "rocm-llvm-clang";
    inherit (rocmPackages.llvm.llvm) version;
    dontPatch = true;
    dontConfigure = true;
    dontBuild = true;
    dontUnpack = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      ln -s ${rocm-llvm-clang-joined} $out
      runHook postInstall
    '';

    passthru = {
      isLLVM = true;
      isClang = true;
    };
  });
in wrapCCWith {
  inherit cc;

  bintools =
    if useLibC
    then rocmPackages.llvm.bintoolsWithLibC
    else rocmPackages.llvm.bintools;

  libc =
    if useLibC
    then rocmPackages.llvm.bintoolsWithLibC.libc
    else rocmPackages.llvm.bintools.libc;

  libcxx =
    if useLibCXX
    then rocmPackages.llvm.libcxx
    else null;

  extraPackages = with rocmPackages.llvm; [
    llvm
  ] ++ lib.optionals useLLD [
    lld
  ] ++ lib.optionals useLibC [
    libc
  ] ++ lib.optionals useLibCXX [
    libcxxabi
    libcxx
  ] ++ lib.optionals useLibUnwind [
    libunwind
  ] ++ lib.optionals useCompilerRt [
    compiler-rt
  ];

  nixSupport.cc-cflags = [
    "-resource-dir=$out/resource-root"
  ] ++ lib.optionals useLLD [
    "-fuse-ld=lld"
  ] ++ lib.optionals useLibUnwind [
    "-unwindlib=libunwind"
  ] ++ lib.optionals useCompilerRt [
    "-rtlib=compiler-rt"
  ] ++ lib.optionals (!disableWarnings) [
    "-Wno-unused-command-line-argument"
  ] ++ lib.optionals disableWarnings [
    # ROCm-related warnings are frequent, spammy, and can impede actual package-side debugging
    "-Wno-everything"
  ];

  extraBuildCommands = ''
    clang_version=$(${cc}/bin/clang -v 2>&1 | grep "clang version " | grep -E -o "[0-9.-]+")
    ln -s ${cc}/lib/clang/$clang_version $out/resource-root

    # Add various binaries that the user may want
    ln -s ${cc}/bin/* $out/bin 2>/dev/null || true
  '';
}
