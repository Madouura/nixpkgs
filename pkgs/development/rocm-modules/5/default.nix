{ lib
, callPackage
, recurseIntoAttrs
, fetchFromGitHub
, rocmPackages_5
, python3Packages
, pkg-config
, elfutils
, boost179
, opencv
, ffmpeg_4
, libjpeg_turbo
, rapidjson-unstable
}:

(callPackage ./aliases.nix { }) // rec {
  ## RadeonOpenCompute ##
  llvm = recurseIntoAttrs (callPackage ./llvm/default.nix { });

  rocm-cmake = util.rocmStdCallPackage ./rocm-cmake { };

  rocm-core = util.rocmStdCallPackage ./rocm-core { };

  rocm-thunk-variants = recurseIntoAttrs
    (callPackage ./rocm-thunk { inherit (util) rocmStdCallPackage; });

  rocm-thunk = rocm-thunk-variants.static;

  # Eventually will be in the LLVM repo
  rocm-device-libs = callPackage ./rocm-device-libs { };

  # Eventually will be in the LLVM repo
  rocm-comgr-variants = callPackage ./rocm-comgr { };

  rocm-comgr = rocm-comgr-variants.shared;

  rocm-runtime-variants = callPackage ./rocm-runtime { };

  rocm-runtime = rocm-runtime-variants.shared.image;

  rocminfo = callPackage ./rocminfo { };

  rocm-smi-variants = recurseIntoAttrs (callPackage ./rocm-smi { });

  rocm-smi = rocm-smi-variants.shared;

  clang-ocl = callPackage ./clang-ocl { };

  # Unfree
  hsa-amd-aqlprofile-bin = callPackage ./hsa-amd-aqlprofile-bin { };

  rdc = callPackage ./rdc { };

  ## ROCm-Developer-Tools ##
  hip-common = callPackage ./hip-common { };

  # Eventually will be in the LLVM repo
  hipcc = callPackage ./hipcc { };

  # Replaces hip, opencl-runtime, and rocclr
  clr-variants = callPackage ./clr { };

  clr = clr-variants.shared;

  hipify = callPackage ./hipify { };

  # Needs GCC
  rocprofiler = callPackage ./rocprofiler { };

  # Needs GCC
  roctracer = callPackage ./roctracer { };

  # Needs GCC
  rocgdb = callPackage ./rocgdb {
    elfutils = elfutils.override { enableDebuginfod = true; };
  };

  rocdbgapi = callPackage ./rocdbgapi { };

  rocr-debug-agent = callPackage ./rocr-debug-agent { };

  ## ROCmSoftwarePlatform ##
  rocprim = callPackage ./rocprim { };

  rocsparse = callPackage ./rocsparse { };

  rocthrust = callPackage ./rocthrust { };

  rocrand = callPackage ./rocrand { };

  hiprand = rocrand; # rocrand includes hiprand

  rocfft = callPackage ./rocfft { };

  rccl = callPackage ./rccl { };

  hipcub = callPackage ./hipcub { };

  hipsparse = callPackage ./hipsparse { };

  hipfort = callPackage ./hipfort { };

  hipfft = callPackage ./hipfft { };

  tensile = python3Packages.callPackage ./tensile { };

  rocblas = callPackage ./rocblas { };

  rocsolver = callPackage ./rocsolver { };

  rocwmma = callPackage ./rocwmma { };

  rocalution = callPackage ./rocalution { };

  rocmlir = callPackage ./rocmlir { };

  rocmlir-rock = rocmlir.override { buildRockCompiler = true; };

  hipsolver = callPackage ./hipsolver { };

  hipblas = callPackage ./hipblas { };

  # hipBlasLt - Very broken with Tensile at the moment, only supports GFX9
  # hipTensor - Only supports GFX9

  miopengemm = callPackage ./miopengemm { };

  composable_kernel = callPackage ./composable_kernel { };

  half = callPackage ./half { };

  miopen = callPackage ./miopen { boost = boost179.override { enableStatic = true; }; };

  miopen-hip = miopen.override { useOpenCL = false; };

  miopen-opencl = miopen.override { useOpenCL = true; };

  migraphx = callPackage ./migraphx { };

  ## GPUOpen-ProfessionalCompute-Libraries ##
  rpp = callPackage ./rpp { };

  rpp-hip = rpp.override {
    useOpenCL = false;
    useCPU = false;
  };

  rpp-opencl = rpp.override {
    useOpenCL = true;
    useCPU = false;
  };

  rpp-cpu = rpp.override {
    useOpenCL = false;
    useCPU = true;
  };

  mivisionx = callPackage ./mivisionx {
    opencv = opencv.override { enablePython = true; };
    ffmpeg = ffmpeg_4;
    rapidjson = rapidjson-unstable;

    # Unfortunately, rocAL needs a custom libjpeg-turbo until further notice
    # See: https://github.com/GPUOpen-ProfessionalCompute-Libraries/MIVisionX/issues/1051
    libjpeg_turbo = libjpeg_turbo.overrideAttrs {
      version = "2.0.6.1";

      src = fetchFromGitHub {
        owner = "rrawther";
        repo = "libjpeg-turbo";
        rev = "640d7ee1917fcd3b6a5271aa6cf4576bccc7c5fb";
        sha256 = "sha256-T52whJ7nZi8jerJaZtYInC2YDN0QM+9tUDqiNr6IsNY=";
      };
    };
  };

  mivisionx-hip = mivisionx.override {
    rpp = rpp-hip;
    useOpenCL = false;
    useCPU = false;
  };

  mivisionx-opencl = mivisionx.override {
    rpp = rpp-opencl;
    miopen = miopen-opencl;
    useOpenCL = true;
    useCPU = false;
  };

  mivisionx-cpu = mivisionx.override {
    rpp = rpp-cpu;
    useOpenCL = false;
    useCPU = true;
  };

  ## Utilities ##
  util = callPackage ./utilities.nix { rocmPackages = rocmPackages_5; };

  ## Meta ##
  meta = callPackage ./meta.nix { rocmPackages = rocmPackages_5; };
}
