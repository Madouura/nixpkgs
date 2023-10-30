{ libxml2 }:

prev: {
  pname = "${prev.pname}-tests-kfdtest";
  sourceRoot = "${prev.src.name}/tests/kfdtest";

  nativeBuildInputs = [
    prev
    libxml2
  ] ++ prev.nativeBuildInputs;

  # Either just broken or needs something
  meta.broken = true;
}
