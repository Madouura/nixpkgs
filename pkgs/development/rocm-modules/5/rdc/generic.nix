{ lib
, fetchFromGitHub
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
, rocmPackages ? { }
, rocmMkDerivation ? { }
, ...
}:

{ buildDocs ? false # Needs internet
, buildTests ? false
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
in rocmMkDerivation {
  inherit buildDocs buildTests;
} (finalAttrs: oldAttrs: {
  pname =
    oldAttrs.pname
  + (
    if buildTests
    then "-test"
    else "-default"
  );

  version = "5.7.1";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rdc";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-xZD/WI/LfNtKK9j6ZjuU0OTTFZz3G4atyD5mVcSsQ8A=";
  };

  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
    protobuf
  ] ++ lib.optionals buildDocs (with rocmPackages; [
    doxygen
    graphviz
    latex
    rocm-docs-core
  ]);

  buildInputs = (with rocmPackages; [
    rocm-runtime
    rocm-smi
    libcap
    grpc
    openssl
  ]) ++ lib.optionals buildTests [
    gtest
  ];

  propagatedBuildInputs = [ python3 ];

  cmakeFlags = oldAttrs.cmakeFlags ++ [
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
  ];

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

  passthru = oldAttrs.passthru // {
    prefixName = "rdc";
    prefixNameSuffix = "-variants";

    unparsedTests = {
      # Test requires the test variant
      rdctst-embedded = "${rocmPackages.rdc-variants.test}/share/rdc/rdctst_tests/rdctst";
      rdctst-standalone = finalAttrs.passthru.unparsedTests.rdctst-embedded;
    };

    impureTests = {
      rdctst-embedded = rocmPackages.util.rocmMakeImpureTest {
        testedPackage = rocmPackages.rdc-variants.test;
        testName = "rdctst-embedded";
        isExecutable = true;
        prefixExecutable = "echo 0 | ";
      };

      rdctst-standalone = rocmPackages.util.rocmMakeImpureTest {
        testedPackage = rocmPackages.rdc-variants.test;
        testName = "rdctst-standalone";
        isExecutable = true;
        prefixExecutable = "echo 1 | ";
      };
    };
  };

  meta = with lib; oldAttrs.meta // {
    description = "Simplifies administration and addresses infrastructure challenges in cluster and datacenter environments";
    homepage = "https://github.com/RadeonOpenCompute/rdc";
    license = with licenses; [ mit ];
  };
})
