{ lib
, buildPythonPackage
, fetchFromGitHub
, pythonOlder
, numpy
, lightning-utilities
, cloudpickle
, scikit-learn
, scikit-image
, packaging
, psutil
, py-deprecate
, torch
, pytestCheckHook
, torchmetrics
, pytorch-lightning
, pytest-doctestplus
, pytest-xdist
}:
let
  pname = "torchmetrics";
  version = "1.2.0";
in buildPythonPackage {
  inherit pname version;
  pyproject = true;
  disabled = pythonOlder "3.8";

  # The repo was moved from PyTorchLightning/metrics to Lightning-AI/torchmetrics
  src = fetchFromGitHub {
    owner = "Lightning-AI";
    repo = "torchmetrics";
    rev = "v${version}";
    hash = "sha256-g5JuTbiRd8yWx2nM3UE8ejOhuZ0XpAQdS5AC9AlrSFY=";
  };

  propagatedBuildInputs = [
    numpy
    lightning-utilities
    packaging
    py-deprecate
  ];

  # Let the user bring their own instance
  buildInputs = [ torch ];

  # A cyclic dependency in: integrations/test_lightning.py
  doCheck = false;

  passthru.tests.check = torchmetrics.overridePythonAttrs {
    pname = "${pname}-check";
    # This is not as clean as I would like it to be, but
    # it will work and tests.check is not user-facing
    catchConflicts = false;
    doCheck = true;

    nativeCheckInputs = [
      pytorch-lightning
      scikit-learn
      scikit-image
      cloudpickle
      psutil
      pytestCheckHook
      pytest-doctestplus
      pytest-xdist
    ];

    disabledTestPaths = [
      # These require too many "leftpad-level" dependencies
      # Also too cross-dependent
      "tests/unittests"

      # A trillion import path mismatch errors
      # Surprisingly, this isn't because of catchConflicts being off...
      "src/torchmetrics"
    ];
  };

  pythonImportsCheck = [ "torchmetrics" ];

  meta = with lib; {
    description = "Machine learning metrics for distributed, scalable PyTorch applications (used in pytorch-lightning)";
    homepage = "https://lightning.ai/docs/torchmetrics/";
    license = licenses.asl20;
    maintainers = with maintainers; [ SomeoneSerge ];
  };
}

