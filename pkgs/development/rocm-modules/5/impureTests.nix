{ lib
, makeImpureTest
, testedPackage
, isNested ? false
}:

let
  trueName = testedPackage.prefixName + lib.optionalString isNested "-variants";
  pnameSplit = lib.splitString "-" (lib.removePrefix testedPackage.prefixName testedPackage.pname);
  pnameConv = lib.concatStringsSep "." pnameSplit;
in makeImpureTest {
  name = lib.last pnameSplit;
  testedPackage = "rocmPackages_5.${trueName + pnameConv}";
  sandboxPaths = [ "/sys" "/dev/dri" "/dev/kfd" ];

  testScript = ''
    echo "'${testedPackage.pname}' built successfully at '${testedPackage}'!"
    echo "'${testedPackage.pname}' tests ran successfully!"
  '';

  meta.maintainers = with lib.maintainers; [ Madouura ];
}
