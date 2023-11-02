{ callPackage
, stdenv ? { }
, rocmPackages ? { }
}:

callPackage ../generic.nix {
  inherit stdenv rocmPackages;
  requiredSystemFeatures = [ "big-parallel" ];
  isBroken = stdenv.isAarch64; # https://github.com/RadeonOpenCompute/ROCm/issues/1831#issuecomment-1278205344
}
