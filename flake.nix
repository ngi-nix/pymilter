{
  description = "A python extension module to enable python scripts to attach to Sendmail's libmilter API, enabling filtering of messages as they arrive";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { self, nixpkgs }:
  let
      pkgs = nixpkgs.outputs.legacyPackages.x86_64-linux;
    in rec {
    packages.x86_64-linux.pymilter = pkgs.python3Packages.buildPythonPackage {
      pname = "pymilter";
      version = "1.0.5";
      src = ./.;
      propagatedBuildInputs = [
        pkgs.libmilter
      ];
      doCheck = false; # to avoid the missing makemap executable of sendmail
      # FIXME: given the manual, "import check is done in it’s own phase, and is not dependent on whether doCheck = true;"
      pythonImportsCheck = [ "Milter" ];
    };

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.pymilter;

  };
}
