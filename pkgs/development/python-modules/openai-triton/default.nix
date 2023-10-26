{ lib
, config
, buildPythonPackage
, fetchFromGitHub
, substituteAll
, addOpenGLRunpath
, pytestCheckHook
, pythonRelaxDepsHook
, pkgsTargetTarget
, cmake
, ninja
, pybind11
, gtest
, zlib
, ncurses
, libxml2
, lit
, llvm
, filelock
, torchWithRocm
, python
, cudaPackages
, cudaSupport ? config.cudaSupport
}:

let
  # A time may come we'll want to be cross-friendly
  #
  # Short explanation: we need pkgsTargetTarget, because we use string
  # interpolation instead of buildInputs.
  #
  # Long explanation: OpenAI/triton downloads and vendors a copy of NVidia's
  # ptxas compiler. We're not running this ptxas on the build machine, but on
  # the user's machine, i.e. our Target platform. The second "Target" in
  # pkgsTargetTarget maybe doesn't matter, because ptxas compiles programs to
  # be executed on the GPU.
  # Cf. https://nixos.org/manual/nixpkgs/unstable/#sec-cross-infra
  ptxas = "${pkgsTargetTarget.cudaPackages.cuda_nvcc}/bin/ptxas"; # Make sure cudaPackages is the right version each update (See python/setup.py)
in
buildPythonPackage rec {
  pname = "triton";
  version = "2.1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "openai";
    repo = pname;
    rev = "da40a1e984bf57c4708daf603eb427442025f99b"; # 2.1.x -- seems to be what pypi is on
    hash = "sha256-aaZzugab+Pdt74Dj6zjlEzjj4BcJ69rzMJmqcVMxsKU=";
  };

  patches = [
    # Necessary fixes according to https://github.com/openai/triton/issues/2479#issuecomment-1757381480
    # https://github.com/openai/triton/pull/2181
    (fetchpatch {
      url = "https://github.com/openai/triton/commit/7fc7c457a00e3870d4c4cf951ba3cfac1eb8e974.patch";
      hash = "sha256-aaahIqHJkVvuil2Yku7vuqWFn7VCRKFSFjYRlwx25ig=";
    })

    (fetchpatch {
      url = "https://github.com/openai/triton/commit/08e55ba61a2dd056958329657b52072dddec45c1.patch";
      hash = "sha256-aaahIqHJkVvuil2Yku7vuqWFn7VCRKFSFjYRlwx25ig=";
    })

    (fetchpatch {
      url = "https://github.com/openai/triton/commit/f498901e348c04fb58927364313ba1626031f79b.patch";
      hash = "sha256-aaahIqHJkVvuil2Yku7vuqWFn7VCRKFSFjYRlwx25ig=";
    })

    (fetchpatch {
      url = "https://github.com/openai/triton/commit/bcf8bd4266c070320e7b4c285232cfe6f4281272.patch";
      hash = "sha256-aaahIqHJkVvuil2Yku7vuqWFn7VCRKFSFjYRlwx25ig=";
    })
  ] ++ lib.optionals (!cudaSupport) [
    # Change hash to not require ptxas
    # https://github.com/openai/triton/pull/2476
    (fetchpatch {
      url = "https://github.com/openai/triton/commit/f0da2374042d061557951cfb308684aa27cbbdc9.patch";
      hash = "sha256-aaahIqHJkVvuil2Yku7vuqWFn7VCRKFSFjYRlwx25ig=";
    })

    (fetchpatch {
      url = "https://github.com/openai/triton/commit/b12aba23f24be17715b546aa8207b91c5ea1880e.patch";
      hash = "sha256-aaahIqHJkVvuil2Yku7vuqWFn7VCRKFSFjYRlwx25ig=";
    })

    (fetchpatch {
      url = "https://github.com/openai/triton/commit/4a3b9e6c10b01b615b78269f9d39f439566040bf.patch";
      hash = "sha256-aaahIqHJkVvuil2Yku7vuqWFn7VCRKFSFjYRlwx25ig=";
    })

    # Make cuda executables optional (Thanks SomeoneSerge!)
    # https://github.com/openai/triton/pull/2546
    (fetchpatch {
      url = "https://github.com/openai/triton/commit/131c4497754664e0923469ffffbdca009579f2c5.patch";
      hash = "sha256-aaahIqHJkVvuil2Yku7vuqWFn7VCRKFSFjYRlwx25ig=";
    })
  ];

  nativeBuildInputs = [
    pythonRelaxDepsHook
    pytestCheckHook
    cmake
    ninja
  ];

  depsTargetTarget = [
    lit
    llvm
  ];

  buildInputs = [
    gtest
    libxml2.dev
    ncurses
    pybind11
    zlib
  ];

  propagatedBuildInputs = [ filelock ];

  postPatch = let
    # Bash was getting weird without linting,
    # but basically upstream contains [cc, ..., "-lcuda", ...]
    # and we replace it with [..., "-lcuda", "-L/run/opengl-driver/lib", "-L$stubs", ...]
    old = [ "-lcuda" ];
    new = [ "-lcuda" "-L${addOpenGLRunpath.driverLink}" "-L${cudaPackages.cuda_cudart}/lib/stubs/" ];

    quote = x: ''"${x}"'';
    oldStr = lib.concatMapStringsSep ", " quote old;
    newStr = lib.concatMapStringsSep ", " quote new;
  in ''
    # Use our `cmakeFlags` instead and avoid downloading dependencies
    substituteInPlace python/setup.py \
      --replace "= get_thirdparty_packages(triton_cache_path)" "= os.environ[\"cmakeFlags\"].split()"

    # Already defined in llvm, when built with -DLLVM_INSTALL_UTILS
    substituteInPlace bin/CMakeLists.txt \
      --replace "add_subdirectory(FileCheck)" ""

    # Don't fetch googletest
    substituteInPlace unittest/CMakeLists.txt \
      --replace "include (\''${CMAKE_CURRENT_SOURCE_DIR}/googletest.cmake)" ""\
      --replace "include(GoogleTest)" "find_package(GTest REQUIRED)"
  '' + lib.optionalString cudaSupport ''
    # Use our linker flags
    substituteInPlace python/triton/compiler.py \
      --replace '${oldStr}' '${newStr}'
  '';

  # Avoid GLIBCXX mismatch with other cuda-enabled python packages
  preConfigure = ''
    # Upstream's setup.py tries to write cache somewhere in ~/
    export HOME=$(mktemp -d)

    # Upstream's github actions patch setup.cfg to write base-dir. May be redundant
    echo "
    [build_ext]
    base-dir=$PWD" >> python/setup.cfg

    # The rest (including buildPhase) is relative to ./python/
    cd python
  '' + lib.optionalString cudaSupport ''
    export CC=${cudaPackages.backendStdenv.cc}/bin/cc;
    export CXX=${cudaPackages.backendStdenv.cc}/bin/c++;

    # Work around download_and_copy_ptxas()
    mkdir -p $PWD/triton/third_party/cuda/bin
    ln -s ${ptxas} $PWD/triton/third_party/cuda/bin
  '';

  # CMake is run by setup.py instead
  dontUseCmakeConfigure = true;

  # Setuptools (?) strips runpath and +x flags. Let's just restore the symlink
  postFixup = lib.optionalString cudaSupport ''
    rm -f $out/${python.sitePackages}/triton/third_party/cuda/bin/ptxas
    ln -s ${ptxas} $out/${python.sitePackages}/triton/third_party/cuda/bin/ptxas
  '';

  checkInputs = [ cmake ]; # ctest
  dontUseSetuptoolsCheck = true;

  preCheck = ''
    # build/temp* refers to build_ext.build_temp (looked up in the build logs)
    (cd /build/source/python/build/temp* ; ctest)

    # For pytestCheckHook
    cd test/unit
  '';

  pythonImportsCheck = [
    "triton"
    "triton.language"
  ];

  # Ultimately, torch is our test suite:
  passthru.tests = {
    inherit torchWithoutCuda torchWithRocm torchWithCuda;
  };

  pythonRemoveDeps = [
    # CLI tools without dist-info
    "cmake"
    "lit"
  ];

  meta = with lib; {
    description = "Language and compiler for writing highly efficient custom Deep-Learning primitives";
    homepage = "https://github.com/openai/triton";
    platforms = lib.platforms.unix;
    license = licenses.mit;
    maintainers = with maintainers; [ SomeoneSerge Madouura ];
  };
}
