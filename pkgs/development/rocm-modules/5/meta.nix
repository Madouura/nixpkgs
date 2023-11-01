{ rocmPackages }:

# Emulate common ROCm meta layout
# These are mainly for users. I strongly suggest NOT using these in nixpkgs derivations
# Don't put these into `propagatedBuildInputs` unless you want PATH/PYTHONPATH issues!
# See: https://rocm.docs.amd.com/en/latest/_images/image.004.png
# See: https://rocm.docs.amd.com/en/latest/deploy/linux/os-native/package_manager_integration.html
let
  rocm-llvm-joined = symlinkJoin {
    name = "rocm-llvm-joined-meta";

    paths = with rocmPackages.llvm; [
      clang
      clang.cc
      mlir
      openmp
    ];

    postBuild = ''
      ln -s $out $out/llvm
    '';
  };
in rec {
  rocm-developer-tools = symlinkJoin {
    name = "rocm-developer-tools-meta";

    paths = with rocmPackages; [
      hsa-amd-aqlprofile-bin
      rocm-core
      rocr-debug-agent
      roctracer
      rocdbgapi
      rocprofiler
      rocgdb
      rocm-language-runtime
    ];
  };

  rocm-ml-sdk = symlinkJoin {
    name = "rocm-ml-sdk-meta";

    paths = with rocmPackages; [
      rocm-core
      miopen-hip
      rocm-hip-sdk
      rocm-ml-libraries
    ];
  };

  rocm-ml-libraries = symlinkJoin {
    name = "rocm-ml-libraries-meta";

    paths = with rocmPackages; [
      rocm-llvm-joined
      rocm-core
      miopen-hip
      rocm-hip-libraries
    ];
  };

  rocm-hip-sdk = symlinkJoin {
    name = "rocm-hip-sdk-meta";

    paths = with rocmPackages; [
      rocprim
      rocalution
      hipfft
      rocm-core
      hipcub
      hipblas
      rocrand
      rocfft
      rocsparse
      rccl
      rocthrust
      rocblas
      hipsparse
      hipfort
      rocwmma
      hipsolver
      rocsolver
      rocm-hip-libraries
      rocm-hip-runtime-devel
    ];
  };

  rocm-hip-libraries = symlinkJoin {
    name = "rocm-hip-libraries-meta";

    paths = with rocmPackages; [
      rocblas
      hipfort
      rocm-core
      rocsolver
      rocalution
      rocrand
      hipblas
      rocfft
      hipfft
      rccl
      rocsparse
      hipsparse
      hipsolver
      rocm-hip-runtime
    ];
  };

  rocm-openmp-sdk = symlinkJoin {
    name = "rocm-openmp-sdk-meta";

    paths = with rocmPackages; [
      rocm-core
      rocm-llvm-joined
      rocm-language-runtime
    ];
  };

  rocm-opencl-sdk = symlinkJoin {
    name = "rocm-opencl-sdk-meta";

    paths = with rocmPackages; [
      rocm-core
      rocm-runtime
      clr
      clr.icd
      rocm-thunk
      rocm-opencl-runtime
    ];
  };

  rocm-opencl-runtime = symlinkJoin {
    name = "rocm-opencl-runtime-meta";

    paths = with rocmPackages; [
      rocm-core
      clr
      clr.icd
      rocm-language-runtime
    ];
  };

  rocm-hip-runtime-devel = symlinkJoin {
    name = "rocm-hip-runtime-devel-meta";

    paths = with rocmPackages; [
      clr
      rocm-core
      hipify
      rocm-cmake
      rocm-llvm-joined
      rocm-thunk
      rocm-runtime
      rocm-hip-runtime
    ];
  };

  rocm-hip-runtime = symlinkJoin {
    name = "rocm-hip-runtime-meta";

    paths = with rocmPackages; [
      rocm-core
      rocminfo
      clr
      rocm-language-runtime
    ];
  };

  rocm-language-runtime = symlinkJoin {
    name = "rocm-language-runtime-meta";

    paths = with rocmPackages; [
      rocm-runtime
      rocm-core
      rocm-comgr
      rocm-llvm-joined
    ];
  };

  rocm-all = symlinkJoin {
    name = "rocm-all-meta";

    paths = [
      rocm-developer-tools
      rocm-ml-sdk
      rocm-ml-libraries
      rocm-hip-sdk
      rocm-hip-libraries
      rocm-openmp-sdk
      rocm-opencl-sdk
      rocm-opencl-runtime
      rocm-hip-runtime-devel
      rocm-hip-runtime
      rocm-language-runtime
    ];
  };
}
