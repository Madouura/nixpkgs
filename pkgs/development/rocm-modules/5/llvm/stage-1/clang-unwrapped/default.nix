{ lib
, rocmPackages
, rPackage
, ...
}:

rPackage {
  targetName = "clang-unwrapped";
  targetDir = "clang";
} (_: oldAttrs: {
  buildInputs = oldAttrs.buildInputs ++ [ rocmPackages.llvm.llvm ];

  cmakeFlags = oldAttrs.cmakeFlags ++ [
    (lib.cmakeBool "LLVM_ENABLE_RTTI" true)
    (lib.cmakeBool "CLANG_INCLUDE_DOCS" true)
    (lib.cmakeBool "CLANG_INCLUDE_TESTS" true)
  ];

  postPatch = ''
    patchShebangs lib/Tooling/DumpTool docs test tools utils www

    # Mainly dependencies not available yet
    cat ${./1000-failing-tests.list} | xargs -d \\n rm
  '';

  postInstall = ''
    patchShebangs $out
    cp -a bin/clang-tblgen $out/bin
  '';

  requiredSystemFeatures = [ "big-parallel" ];
  passthru.isClang = true;
})
