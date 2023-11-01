{ lib
, writeScript
, version ? ""
}:

{ name ? ""
, owner ? ""
, repo ? ""
, page ? "releases/latest"
, filter ? ".tag_name | split(\"-\") | .[1]"
}:

let
  updateScript = let
    pname =
      if lib.hasPrefix "rocm-llvm-" name
      then "llvm." + (lib.removePrefix "rocm-llvm-" name)
      else name;

    major = lib.versions.major version;
  in writeScript "update.sh" ''
    #!/usr/bin/env nix-shell
    #!nix-shell -i bash -p curl jq common-updater-scripts
    version="$(curl ''${GITHUB_TOKEN:+-u ":$GITHUB_TOKEN"} \
      -sL "https://api.github.com/repos/${owner}/${repo}/${page}" | jq '${filter}' --raw-output)"

    IFS='.' read -a version_arr <<< "$version"

    if [ "${major}" == "''${version_arr[0]}" ]; then
      if [ "''${#version_arr[*]}" == "2" ]; then
        version="''${version}.0"
      fi

      update-source-version "rocmPackages_${major}.${pname}" "$version" --ignore-same-hash
    fi
  '';
in [ updateScript ]
