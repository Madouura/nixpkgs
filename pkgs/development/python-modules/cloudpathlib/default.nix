{ lib
, buildPythonPackage
, fetchPypi
, pythonOlder
, pytestCheckHook
, flit-core
, typing-extensions
}:

buildPythonPackage rec {
  pname = "cloudpathlib";
  version = "0.16.0";
  pyproject = true;
  disabled = pythonOlder "3.7";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-zfzTXUbVKVh9dEFUoL35YqypU7clyHhM0uxHg1TqY6M=";
  };

  nativeBuildInputs = [ flit-core ];
  propagatedBuildInputs = lib.optionals (pythonOlder "3.11") [ typing-extensions ];
  # __main__.py: error: unrecognized arguments: --cov=cloudpathlib --cov-report=term --cov-report=html --cov-report=xml -n=auto
  doCheck = false;
  nativeCheckInputs = [ pytestCheckHook ];
  pythonImportsCheck = [ "cloudpathlib" ];

  meta = with lib; {
    description = "Pathlib-style classes for cloud storage services such as Amazon S3, Azure Blob Storage, and Google Cloud Storage";
    homepage = "https://cloudpathlib.drivendata.org/stable";
    changelog = "https://github.com/drivendataorg/cloudpathlib/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ Madouura ];
  };
}
