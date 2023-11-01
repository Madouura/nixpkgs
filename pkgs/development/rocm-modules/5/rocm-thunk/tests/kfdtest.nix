{ testedPackage ? { }
, rocmPackages ? { }
, libxml2
}:

prev: {
  pname = "${prev.pname}-tests-kfdtest";
  sourceRoot = "${prev.src.name}/tests/kfdtest";

  nativeBuildInputs = with rocmPackages; [
    testedPackage
    llvm.llvm
    libxml2
  ] ++ prev.nativeBuildInputs;

  # Unsure what's missing
  meta.broken = true;
}
