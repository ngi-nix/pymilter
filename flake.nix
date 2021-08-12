{
  description = "A python extension module to enable python scripts to attach to Sendmail's libmilter API, enabling filtering of messages as they arrive";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });
    in {
      overlay = final: prev: { pymilter = (import ./default.nix { pkgs = final; }); };
      packages = forAllSystems (system: {inherit (nixpkgsFor.${system}) pymilter; });
      defaultPackage = forAllSystems (system: self.packages.${system}.pymilter);
      checks = forAllSystems (system: { inherit (self.packages.${system}) pymilter; });
      devShell = forAllSystems (system: nixpkgsFor.${system}.mkShell {

        # FIXME, in this case, why can I import Milter, I thought only pymilter dependencies would be in the dev shell
        # inputsFrom = [ self.packages.${system}.pymilter ];

        inputsFrom = [ ];
        packages = [ ];
      });
    };
}
