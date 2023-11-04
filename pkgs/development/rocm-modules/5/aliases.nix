{ rocmPackages_common }:

{
  hip-common = throw "'rocmPackages_5.hip-common' has been moved into 'rocmPackages_5.clr'"; # Added 2023-11-03

  hipcc = throw "'rocmPackages_5.hipcc' has been moved into 'rocmPackages_5.clr'"; # Added 2023-11-03

  rocm-docs-core = rocmPackages_common.rocm-docs-core; # Added 2023-11-01
}
