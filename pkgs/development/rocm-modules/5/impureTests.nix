{ lib
, makeImpureTest
, testedPackage
, testName
, isNested ? false
, isExecutable ? false
}:

let
  trueName = testedPackage.prefixName + lib.optionalString isNested "-variants";
  pnameSplit = lib.splitString "-" (lib.removePrefix testedPackage.prefixName testedPackage.pname);
  pnameConv = lib.concatStringsSep "." pnameSplit;
  convPackage = "rocmPackages_5.${trueName + pnameConv}";
in makeImpureTest {
  name = testName;
  testedPackage = convPackage;
  sandboxPaths = [ "/sys" "/dev/dri" "/dev/kfd" ];

  testScript = let
    overridePackage =
      if testedPackage.tests.${testName}.meta.broken
      then testedPackage.tests.${testName}.overrideAttrs { meta.broken = false; }
      else testedPackage.tests.${testName};
  in ''
    GREENB="\e[1;32m"
    BLUEB="\e[1;34m"
    BLUEBI="\e[1;3;4;34m"
    END="\e[0m"
    echo -e "''${GREENB}${convPackage}:''${END} ''${BLUEB}Test built successfully at ''${END}''${BLUEBI}${overridePackage}''${END}''${BLUEB}!''${END}"
  '' + lib.optionalString isExecutable ''
    echo -e "''${GREENB}${convPackage}:''${END} ''${BLUEB}Running ''${END}''${BLUEBI}${testName}''${END} ''${BLUEB}test...''${END}"
    ${overridePackage}
  '' + ''
    echo -e "''${GREENB}${convPackage}:''${END} ''${BLUEB}Test ran successfully!''${END}"
  '';

  meta.maintainers = with lib.maintainers; [ Madouura ];
}
