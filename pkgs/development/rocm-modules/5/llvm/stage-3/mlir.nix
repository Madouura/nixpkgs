{ lib
, callPackage
, vulkan-headers
, vulkan-loader
, glslang
, shaderc
, lit
, stdenv ? { }
, rocmPackages ? { }
}:

let
  targetName = "mlir";
in callPackage ../generic.nix {
  inherit stdenv rocmPackages targetName;
  buildDocs = false; # No decent way to hack this to work
  buildMan = false; # No man pages to build
  targetDir = targetName;

  # Fix `DebugTranslation.cpp:139:10: error: no matching function for call to 'get'`
  # We patch at a different source root, so we modify the patch and include it locally
  # https://github.com/RadeonOpenCompute/llvm-project/commit/f1d1e10ec7e1061bf0b90abbc1e298d9438a5e74.patch
  extraPatches = [ ./0000-mlir-fix-debugtranslation.patch ];
  extraNativeBuildInputs = [ rocmPackages.clr ];

  extraBuildInputs = [
    vulkan-headers
    vulkan-loader
    glslang
    shaderc
  ];

  extraCMakeFlags = [
    (lib.cmakeBool "MLIR_INCLUDE_DOCS" true)
    (lib.cmakeBool "MLIR_INCLUDE_TESTS" true)
    (lib.cmakeBool "MLIR_ENABLE_ROCM_RUNNER" true)
    (lib.cmakeBool "MLIR_ENABLE_SPIRV_CPU_RUNNER" true)
    (lib.cmakeBool "MLIR_ENABLE_VULKAN_RUNNER" true)
    (lib.cmakeFeature "ROCM_TEST_CHIPSET" "gfx000")
  ];

  extraPostPatch = ''
    # `add_library cannot create target "llvm_gtest" because an imported target with the same name already exists`
    substituteInPlace CMakeLists.txt \
      --replace "EXISTS \''${UNITTEST_DIR}/googletest/include/gtest/gtest.h" "FALSE"

    # Mainly `No such file or directory`
    cat ${./1001-mlir-failing-tests.list} | xargs -d \\n rm
  '';

  extraPostInstall = ''
    mkdir -p $out/bin
    cp -a bin/mlir-tblgen $out/bin
  '';

  checkTargets = [ "check-${targetName}" ];
  requiredSystemFeatures = [ "big-parallel" ];
}
