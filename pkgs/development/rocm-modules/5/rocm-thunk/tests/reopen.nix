{ testPackage }:

prev: {
  pname = "${prev.pname}-tests-reopen";
  sourceRoot = "${prev.src.name}/tests/reopen";

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace "\''$ENV{ROOT_OF_ROOTS}/out/lib" "\"${testPackage}/lib\"" \
      --replace "\''$ENV{LIBHSAKMT_ROOT}" "${testPackage}"

    substituteInPlace kmtreopen.c \
      --replace "libhsakmt.so" "${testPackage}/lib/libhsakmt.so"
  '';

  doCheck = true;

  checkPhase = ''
    runHook preCheck
    ./kmtreopen
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    touch $out
    runHook postInstall
  '';

  meta.broken = true;
}
