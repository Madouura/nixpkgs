{ lib
, stdenv
, fetchFromGitHub
, commonNativeBuildInputs
, commonCMakeFlags
, rocmUpdateScript
, rocmPackages_5
, protobuf
, libcap
, grpc
, openssl
, python3
, util-linux
, texlive
, doxygen
, graphviz
, gtest
, callPackage
, buildDocs ? false # Needs internet
, buildTests ? true
}:

let
  latex = lib.optionalAttrs buildDocs texlive.combine {
    inherit (texlive) scheme-small
    changepage
    latexmk
    varwidth
    multirow
    hanging
    adjustbox
    collectbox
    stackengine
    enumitem
    alphalph
    wasysym
    sectsty
    tocloft
    newunicodechar
    etoc
    helvetic
    wasy
    courier;
  };
in stdenv.mkDerivation (finalAttrs: {
  pname = finalAttrs.passthru.prefixName;
  version = "5.7.1";

  outputs = [
    "out"
  ] ++ lib.optionals buildDocs [
    "doc"
  ];

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rdc";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-xZD/WI/LfNtKK9j6ZjuU0OTTFZz3G4atyD5mVcSsQ8A=";
  };

  nativeBuildInputs = [
    protobuf
  ] ++ lib.optionals buildDocs (with rocmPackages_5; [
    doxygen
    graphviz
    latex
    rocm-docs-core
  ]) ++ commonNativeBuildInputs;

  buildInputs = (with rocmPackages_5; [
    rocm-smi
    rocm-runtime
    libcap
    grpc
    openssl
  ]) ++ lib.optionals buildTests [
    gtest
  ];

  propagatedBuildInputs = [ python3 ];

  cmakeFlags = [
    # Keep in line with `gRPC` and `protobuf` C++ standard
    (lib.cmakeFeature "CMAKE_CXX_STANDARD" "17")
    # `raslib` doesn't actually exist, lol
    (lib.cmakeBool "BUILD_RASLIB" false)
    (lib.cmakeBool "BUILD_ROCRTEST" true)
    # Not sure what `rocmtools` is...
    (lib.cmakeBool "BUILD_ROCPTEST" false)
    (lib.cmakeBool "BUILD_TESTS" buildTests)
    (lib.cmakeFeature "GRPC_ROOT" "${grpc}")
    (lib.cmakeFeature "ROCM_DIR" (placeholder "out"))
  ] ++ commonCMakeFlags;

  postPatch = ''
    patchShebangs cmake_modules server src authentication

    substituteInPlace CMakeLists.txt \
      --replace "file(STRINGS /etc/os-release LINUX_DISTRO LIMIT_COUNT 1 REGEX \"NAME=\")" "set(LINUX_DISTRO \"NixOS\")"

    substituteInPlace server/rdc.service.in \
      --replace "/bin/kill" "${util-linux}/bin/kill"

    substituteInPlace rdc_libs/bootstrap/src/RdcBootStrap.cc \
      --replace "librdc.so" "$out/lib/librdc.so" \
      --replace "librdc_client.so" "$out/lib/librdc_client.so"

    substituteInPlace rdc_libs/rdc/src/RdcModuleMgrImpl.cc \
      --replace "librdc_ras.so" "$out/lib/rdc/librdc_ras.so" \
      --replace "librdc_rocr.so" "$out/lib/rdc/librdc_rocr.so"

    substituteInPlace rdc_libs/rdc_modules/rdc_rocr/base_rocr_utils.cc \
      --replace "librdc_rocr.so" "$out/lib/rdc/librdc_rocr.so"

    substituteInPlace python_binding/rdc_bootstrap.py \
      --replace "librdc_bootstrap.so" "$out/lib/librdc_bootstrap.so"

    substituteInPlace tests/rdc_tests/CMakeLists.txt \
      --replace "''\$ORIGIN/../../../lib" "$out/lib"

    substituteInPlace tests/rdc_tests/{main,test_common}.cc \
      --replace "/usr/sbin/rdcd" "$out/bin/rdcd"
  '';

  postInstall = ''
    find $out/bin -executable -type f -exec \
      patchelf {} --shrink-rpath --allowed-rpath-prefixes $NIX_STORE \;
  '' + lib.optionalString buildDocs ''
    cd ../docs
    python3 -m sphinx -T -E -b html -d _build/doctrees -D language=en . _build/html
  '';

  postFixup = ''
    chmod +x $out/lib/rdc/librdc_ras.so
    patchelf $out/lib/rdc/librdc_ras.so --set-rpath $out/lib:$out/lib/rdc
  '';

  passthru = {
    prefixName = "rdc";

    tests = {
      rdctst-embedded = callPackage ./tests/rdctst.nix { testedPackage = finalAttrs.finalPackage; };
      rdctst-standalone = finalAttrs.passthru.tests.rdctst-embedded;
    };

    impureTests = {
      rdctst-embedded = callPackage ../impureTests.nix {
        testedPackage = finalAttrs.finalPackage;
        testName = "rdctst-embedded";
        isExecutable = true;
        prefixExec = "echo 0 | ";
      };

      rdctst-standalone = callPackage ../impureTests.nix {
        testedPackage = finalAttrs.finalPackage;
        testName = "rdctst-standalone";
        isExecutable = true;
        prefixExec = "echo 1 | ";
      };
    };

    updateScript = rocmUpdateScript {
      name = finalAttrs.pname;
      owner = finalAttrs.src.owner;
      repo = finalAttrs.src.repo;
    };
  };

  meta = with lib; {
    description = "Simplifies administration and addresses infrastructure challenges in cluster and datacenter environments";
    homepage = "https://github.com/RadeonOpenCompute/rdc";
    license = with licenses; [ mit ];
    maintainers = teams.rocm.members;
    platforms = platforms.linux;
    broken = versions.minor finalAttrs.version != versions.minor rocmPackages_5.llvm.llvm.version;
  };
})
