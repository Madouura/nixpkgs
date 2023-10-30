{ libxml2 }:

prev: {
  pname = "${prev.pname}-tests-kfdtest";
  sourceRoot = "${prev.src.name}/tests/kfdtest";

  nativeBuildInputs = prev.nativeBuildInputs ++ [
    prev
    libxml2
  ];

  # Either just broken or needs something
  meta.broken = true;
}
