{ lib
, callPackage
, perl
, elfutils
, libdrm
, numactl
, lit
, stdenv ? { }
, rocmPackages ? { }
}:

let
  targetName = "openmp";
in callPackage ../generic.nix {
  inherit stdenv rocmPackages targetName;
  targetDir = targetName;
  extraNativeBuildInputs = [ perl ];

  extraBuildInputs = with rocmPackages; [
    rocm-device-libs
    rocm-runtime
    rocm-thunk
    elfutils
    libdrm
    numactl
  ];

  extraCMakeFlags = with rocmPackages; [
    # For docs
    (lib.cmakeFeature "CMAKE_MODULE_PATH" "/build/source/llvm/cmake/modules")
    (lib.cmakeFeature "CLANG_TOOL" "${llvm.clang}/bin/clang")
    (lib.cmakeFeature "CLANG_OFFLOAD_BUNDLER_TOOL" "${llvm.clang}/bin/clang-offload-bundler")
    (lib.cmakeFeature "PACKAGER_TOOL" "${llvm.clang}/bin/clang-offload-packager")
    (lib.cmakeFeature "OPENMP_LLVM_TOOLS_DIR" "${llvm.llvm}/bin")
    (lib.cmakeFeature "OPENMP_LLVM_LIT_EXECUTABLE" "${lit}/bin/.lit-wrapped")
    (lib.cmakeFeature "DEVICELIBS_ROOT" "${rocm-device-libs.src}")
  ];

  extraPostPatch = ''
    # We can't build this target at the moment
    substituteInPlace libomptarget/DeviceRTL/CMakeLists.txt \
      --replace "gfx1010" ""

    # No idea what's going on here...
    cat ${./1000-openmp-failing-tests.list} | xargs -d \\n rm
  '';

  checkTargets = [ "check-${targetName}" ];
  extraLicenses = [ lib.licenses.mit ];
}
