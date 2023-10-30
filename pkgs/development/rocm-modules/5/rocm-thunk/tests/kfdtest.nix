{ libxml2 }:

prev: {
  pname = "${prev.pname}-tests-kfdtest";
  sourceRoot = "${prev.src.name}/tests/kfdtest";

  nativeBuildInputs = [
    prev
    libxml2
  ] ++ prev.nativeBuildInputs;

  meta = with lib; {
    maintainers = teams.rocm.members;
    # Needs to be ran in `impureTests`
    broken = true;
  };
}
