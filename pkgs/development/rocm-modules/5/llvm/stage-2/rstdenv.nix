{ overrideCC
, wrapCCWith
, stdenv ? { }
, rocmPackages ? { }
, runtimes ? { }
}:

let
  cc = rocmPackages.llvm.clang-unwrapped;
in overrideCC stdenv (wrapCCWith {
  inherit cc;
  inherit (rocmPackages.llvm) bintools;

  extraPackages = with rocmPackages.llvm; [
    llvm
    lld
    runtimes
  ];

  nixSupport.cc-cflags = [
    "-resource-dir=$out/resource-root"
    "-fuse-ld=lld"
    "-rtlib=compiler-rt"
    "-unwindlib=libunwind"
    "-Wno-unused-command-line-argument"
  ];

  extraBuildCommands = ''
    clang_version=`${cc}/bin/clang -v 2>&1 | grep "clang version " | grep -E -o "[0-9.-]+"`
    mkdir -p $out/resource-root
    ln -s ${cc}/lib/clang/$clang_version/include $out/resource-root
    ln -s ${runtimes}/lib $out/resource-root
  '';
})
