{ lib
, makeImpureTest
, rocmVersion ? ""
}:

{ testedPackage ? { }
, testName ? ""
, isExecutable ? false
, prefixExecutable ? ""
, executableSuffix ? ""
# `bypassTestScript` is for when we can't normally run a test to completion.
# This is because of `nix-build` internal permission issues, we NEED root.
# So, run it in `prepareRunCommands` and exit before the normal script.
# If possible, please check if you can't just add a path to `sandBoxPaths` instead.
, bypassTestScript ? false
, sandboxPaths ? [ "/sys" "/dev/dri" "/dev/kfd" ]
, prepareRunCommands ? ""
}:

let
  testedPackage' =
    "rocmPackages_${rocmVersion}."
  + testedPackage.prefixName
  + lib.optionalString (lib.hasAttr "prefixNameSuffix" testedPackage)
      testedPackage.prefixNameSuffix
  + "."
  + lib.replaceStrings [ "-" "." ] [ "" "" ]
      (lib.removePrefix testedPackage.prefixName (lib.getName testedPackage));

  testedPackageTest = testedPackage.unparsedTests.${testName};

  commonStart = ''
    RT_GREENB="\e[1;32m"
    RT_BLUEB="\e[1;34m"
    RT_BLUEBI="\e[1;3;4;34m"
    RT_END="\e[0m"
    RT_PREFIX="''${RT_GREENB}${testedPackage'}:''${RT_END}"

    echo -e "$RT_PREFIX ''${RT_BLUEB}Test built successfully at" \
      "''${RT_END}''${RT_BLUEBI}${testedPackageTest}''${RT_END}''${RT_BLUEB}!''${RT_END}"
  '';

  commonMiddle = ''
    echo -e "$RT_PREFIX ''${RT_BLUEB}Running ''${RT_END}''${RT_BLUEBI}${testName}''${RT_END}" \
      "''${RT_BLUEB}test...''${RT_END}"
  '';

  commonEnd = ''
    echo -e "$RT_PREFIX ''${RT_BLUEB}Test" \
      "''${RT_BLUEBI}${testName}''${RT_END} ''${RT_BLUEB}ran successfully!''${RT_END}"

    unset RT_PREFIX
    unset RT_GREENB
    unset RT_BLUEB
    unset RT_BLUEBI
    unset RT_END
  '';
in makeImpureTest {
  name = testName;
  testedPackage = testedPackage';
  inherit sandboxPaths;

  prepareRunCommands =
    lib.optionalString bypassTestScript (
      commonStart
    + commonMiddle
    + ''
        ${prefixExecutable}sudo ${testedPackageTest + executableSuffix}
        RT_YELB="\e[1;33m"
        RT_YELBI="\e[1;3;4;33m"

        echo -e "$RT_PREFIX ''${RT_YELB}This test normally errors due to" \
          "''${RT_YELBI}nix''${RT_END}''${RT_YELB}.\n''${RT_END}''${RT_YELBI}nix-build''${RT_END}" \
          "''${RT_YELB}needs to run as root internally or work around" \
          "setuid and password for ''${RT_END}''${RT_YELBI}sudo''${RT_END}''${RT_YELB}.\nThus," \
          "we run ''${RT_END}''${RT_YELBI}sudo ${testedPackageTest}''${RT_END}''${RT_YELB}\nbefore" \
          "the test script and exit early.''${RT_END}"

        unset RT_YELB
        unset RT_YELBI
      ''
    )
  + prepareRunCommands
  + lib.optionalString bypassTestScript
      (commonEnd + "exit 0\n");

  testScript =
    commonStart
  + lib.optionalString isExecutable
    "${commonMiddle + prefixExecutable + testedPackageTest + executableSuffix}\n"
  + commonEnd;

  meta = with lib; {
    maintainers = teams.rocm.members;

    broken =
      testedPackage == { } ||
      testName == "" ||
      (bypassTestScript && !isExecutable);
  };
}
