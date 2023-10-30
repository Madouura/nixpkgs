{ libxml2 }:

prev: {
  pname = "${prev.pname}-tests-kfdtest";
  sourceRoot = "${prev.src.name}/tests/kfdtest";

  nativeBuildInputs = prev.nativeBuildInputs ++ [
    prev
    libxml2
  ];

  meta.broken = true;
}
