{ lib
, buildPythonPackage
, fetchPypi
, pythonOlder
, pytestCheckHook
, setuptools
, typer
, requests
, wasabi
, srsly
, confection
, cloudpathlib
, smart-open
}:

buildPythonPackage rec {
  pname = "weasel";
  version = "0.3.3";
  pyproject = true;
  disabled = pythonOlder "3.6";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-kkli38nYlgJVLnMyhG6V0mTsoYrr4rlsJSfUa3u3z5w=";
  };

  nativeBuildInputs = [ setuptools ];

  propagatedBuildInputs = [
    typer
    requests
    wasabi
    srsly
    confection
  ];

  nativeCheckInputs = [
    pytestCheckHook
    cloudpathlib
    smart-open
  ];

  disabledTests = [
    # Assertion failure
    "test_project_assets"
  ];

  pythonImportsCheck = [ "weasel" ];

  meta = with lib; {
    description = "Small and easy workflow system";
    homepage = "https://github.com/explosion/weasel";
    changelog = "https://github.com/explosion/weasel/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ Madouura ];
  };
}
