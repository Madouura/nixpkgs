{ lib
, buildPythonPackage
, fetchPypi
, pytestCheckHook
, pythonOlder
, setuptools
, pybind11
, numpy
}:

buildPythonPackage rec {
  pname = "floret";
  version = "0.10.4";
  pyproject = true;
  disabled = pythonOlder "3.7";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-Z6GeP8r5Anh73PGOvfdaafcdLRl0T1D0LvJkMFuqiY0=";
  };

  nativeBuildInputs = [ setuptools ];
  propagatedBuildInputs = [ pybind11 ];

  nativeCheckInputs = [
    pytestCheckHook
    numpy
  ];

  pythonImportsCheck = [ "floret" ];

  meta = with lib; {
    description = "Bloom embeddings for compact, full-coverage vectors with spaCy ";
    homepage = "https://github.com/explosion/floret";
    license = licenses.mit;
    maintainers = with maintainers; [ Madouura ];
  };
}
