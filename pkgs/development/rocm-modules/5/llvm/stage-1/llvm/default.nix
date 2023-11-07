{ lib
, rPackage
, libbfd
, ...
}:

rPackage { } (_: oldAttrs: {
  cmakeFlags = oldAttrs.cmakeFlags ++ [
    (lib.cmakeBool "LLVM_ENABLE_RTTI" true)
    (lib.cmakeBool "LLVM_ENABLE_FFI" true)
    (lib.cmakeBool "LLVM_INSTALL_UTILS" true)
    (lib.cmakeBool "LLVM_INSTALL_GTEST" true)
    (lib.cmakeBool "LLVM_LINK_LLVM_DYLIB" true)
    (lib.cmakeFeature "LLVM_BINUTILS_INCDIR" "${lib.getDev libbfd}/include")
  ];

  postPatch = ''
    patchShebangs lib/OffloadArch tools utils test

    # FileSystem permissions tests fail with various special bits
    rm test/tools/llvm-objcopy/ELF/mirror-permissions-unix.test
    rm unittests/Support/Path.cpp

    substituteInPlace unittests/Support/CMakeLists.txt \
      --replace "Path.cpp" ""
  '';

  postInstall = ''
    patchShebangs $out/share/opt-viewer
  '';

  requiredSystemFeatures = [ "big-parallel" ];
  passthru.isLLVM = true;
})
