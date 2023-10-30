{ testedPackage ? { } }:

prev: {
  pname = "${prev.pname}-tests-reopen";
  sourceRoot = "${prev.src.name}/tests/reopen";

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace "\''$ENV{ROOT_OF_ROOTS}/out/lib" "\"${testedPackage}/lib\"" \
      --replace "\''$ENV{LIBHSAKMT_ROOT}" "${testedPackage}"

    substituteInPlace kmtreopen.c \
      --replace "libhsakmt.so" "${testedPackage}/lib/libhsakmt.so"
  '';

  installPhase = ''
    runHook preInstall
    cp -a kmtreopen $out
    runHook postInstall
  '';

  # Needs to be ran in `impureTests`
  meta.broken = true;
}
