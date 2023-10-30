{ lib
, stdenv
, fetchFromGitHub
, pkg-config
, cmake
, glew
, freeglut
, opencl-headers
, ocl-icd
, testedPackage ? { }
}:

stdenv.mkDerivation {
  pname = "amd-app-samples";
  version = "2018-06-10";

  src = fetchFromGitHub {
    owner = "OpenCL";
    repo = "AMD_APP_samples";
    rev = "54da6ca465634e78fc51fc25edf5840467ee2411";
    hash = "sha256-qARQpUiYsamHbko/I1gPZE9pUGJ+3396Vk2n7ERSftA=";
  };

  nativeBuildInputs = [
    pkg-config
    cmake
  ];

  buildInputs = [
    glew
    freeglut
    opencl-headers
    ocl-icd
    testedPackage
    (lib.getOutput "icd" testedPackage)
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_CPP_CL" false)
  ];

  doCheck = true;

  checkPhase = ''
    runHook preCheck = true;

    # Examples load resources from current directory
    cd bin
    mv */*/*/*/* .

    export OCL_ICD_VENDORS="${testedPackage.icd}/etc/OpenCL/vendors"
    echo OCL_ICD_VENDORS=$OCL_ICD_VENDORS
    pwd
    ./HelloWorld | grep HelloWorld
    touch $out

    runHook postCheck = true;
  '';

  dontInstall = true;
  dontFixup = true;

  meta = with lib; {
    description = "Samples from the AMD APP SDK (with OpenCRun support)";
    homepage = "https://github.com/OpenCL/AMD_APP_samples";
    license = licenses.bsd2;
    platforms = platforms.linux;
    maintainers = lib.teams.rocm.members;
    # Needs to be ran in `impureTests`
    broken = true;
  };
}
