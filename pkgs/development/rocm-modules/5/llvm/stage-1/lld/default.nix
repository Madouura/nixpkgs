{ rocmPackages
, rPackage
, ...
}:

let
  targetName = "lld";
in rPackage {
  inherit targetName;
  # No man pages to build
  buildMan = false;
  targetDir = targetName;
} (_: oldAttrs: {
  buildInputs = oldAttrs.buildInputs ++ [ rocmPackages.llvm.llvm ];

  postPatch = ''
    patchShebangs test utils
  '';
})
