{ lib
, makeImpureTest
, testedPackage ? { }
, testName ? ""
, isNested ? false
, isExecutable ? false
, prefixExec ? ""
# `bypassTestScript` is for when we can't normally run a test to completion.
# This is because of nix-build internal permission issues, we NEED root.
# So, run it in `prepareRunCommands` and exit before the normal script.
# If possible, please check if you can't just add a path to `sandBoxPaths` instead.
, bypassTestScript ? false
, sandboxPaths ? [ "/sys" "/dev/dri" "/dev/kfd" ]
, prepareRunCommands ? ""
}:

let
  trueName = testedPackage.prefixName + lib.optionalString isNested "-variants";
  pnameSplit = lib.splitString "-" (lib.removePrefix testedPackage.prefixName testedPackage.pname);
  pnameConv = lib.concatStringsSep "." pnameSplit;
  convPackage = "rocmPackages_5.${trueName + pnameConv}";

  overridePackage =
      if testedPackage.tests.${testName}.meta.broken
      then testedPackage.tests.${testName}.overrideAttrs { meta.broken = false; }
      else testedPackage.tests.${testName};

  commonStart = ''
    GREENB="\e[1;32m"
    BLUEB="\e[1;34m"
    BLUEBI="\e[1;3;4;34m"
    END="\e[0m"

    echo -e "''${GREENB}${convPackage}:''${END} ''${BLUEB}Test built successfully at ''${END}''${BLUEBI}${overridePackage}''${END}''${BLUEB}!''${END}"
  '';

  commonMid = ''
    echo -e "''${GREENB}${convPackage}:''${END} ''${BLUEB}Running ''${END}''${BLUEBI}${testName}''${END} ''${BLUEB}test...''${END}"
  '';

  commonEnd = ''
    echo -e "''${GREENB}${convPackage}:''${END} ''${BLUEB}Test ran successfully!''${END}"

    unset GREENB
    unset BLUEB
    unset BLUEBI
    unset END
  '';
in makeImpureTest {
  name = testName;
  testedPackage = convPackage;
  inherit sandboxPaths;

  prepareRunCommands =
    lib.optionalString bypassTestScript (commonStart + commonMid + ''
      ${prefixExec}sudo ${overridePackage}
      YELB="\e[1;33m"
      YELBI="\e[1;3;4;33m"

      echo -e "''${GREENB}${convPackage}:''${END} ''${YELB}This test normally errors due to ''${YELBI}nix''${END}''${YELB}.
      ''${END}''${YELBI}nix-build''${END} ''${YELB}needs to run as root internally or work around setuid and password for ''${END}''${YELBI}sudo''${END}''${YELB}.
      Thus, we run ''${END}''${YELBI}sudo ${overridePackage}''${END}''${YELB}
      before the test script and exit early.''${END}"

      unset YELB
      unset YELBI
    '')
  + prepareRunCommands
  + lib.optionalString bypassTestScript (commonEnd + ''
    exit 0
  '');

  testScript =
    commonStart
  + lib.optionalString isExecutable (commonMid + ''
    ${prefixExec + overridePackage}
  '')
  + commonEnd;

  meta = {
    maintainers = with lib.maintainers; [ Madouura ];
    broken = (bypassTestScript && !isExecutable);
  };
}
