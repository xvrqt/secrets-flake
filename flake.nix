# This flake collates all my host flakes together for convenienc0
{
  inputs = {
    # Our secret keeping scheme
    agenix.url = "github:ryantm/agenix";
  };
  outputs = { agenix, ... }: rec {
    nixosModules = {
      # Import me to import Agenix and it's bare minimum configuration
      default = { pkgs, ... }:
        let
          keyPath = "/key";
          secretPath = "${keyPath}/secrets";
          agenixPath = "${keyPath}/agenix";
          identityPath = "${agenixPath}/keys";
          generationPath = "${agenixPath}/generations";

          # Create paths to the Agenix keys that will be used to decrypt secrets
          keys = publicKeys;
          users = keys.users;
          machines = keys.machines;
          identityPaths = (map
            (name: "${identityPath}/${name}.agenix")
            ((builtins.attrNames users) ++ (builtins.attrNames machines)));
        in
        {
          imports = [
            agenix.nixosModules.default
          ];
          # Install secret management tooling
          environment.systemPackages = [
            # age key generation and management
            pkgs.age
            agenix.packages.${pkgs.system}.default
          ];
          # We will always store our secrets on a removable 'key'
          age = {
            # Where the secrets will by symlinked/deployed to
            # Where applications should look for them
            secretsDir = secretPath;
            # Where the secrets per generation are created
            # (and then symlinked to secretsDir)
            secretsMountPoint = generationPath;
            # Where to look for keys to decrypt secrets
            inherit identityPaths;
          };
        };
    };
    # Public keys can be kept here, so they only need to be updated in one place
    # These keys encrypt all other secrets
    publicKeys = {
      machines = {
        nyaa = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINtHIPfa2+AQGIHZcBRLgkIx+3mhwEt/zf5ClP2AVvZ+ nyaa@machine";
        spark = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEDnpWeIBR+QCwclhSqSDKTsYCLYPX0b38lYnKPYBEMM spark@machine";
        archive = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO6GH/nzYFaruIZ9ZORbBhYEzTHBnrCZXSJUK2rrs1jL archive@machine";
      };
      users = {
        crow = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHTsYcLV5djsXoISRIysYrbHOnPHt3SIqtXdiWIJ+m0Y crow@agenix";
      };
    };
  };
}
