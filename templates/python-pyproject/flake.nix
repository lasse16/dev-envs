{
  description = "A template for a devshell based on pyproject.toml";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    pyproject-nix.url = "github:pyproject-nix/pyproject.nix";
    pyproject-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    pyproject-nix,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    project = pyproject-nix.lib.project.loadPyproject {
      projectRoot = ./.;
    };

    #CHANGE THIS IF YOU REQUIRE A NEWER VERSION
    python = pkgs.python311;

    # Validate that our Python satisfies requires-python from pyproject.toml
    pythonVersion = pyproject-nix.lib.pep440.parseVersion python.pythonVersion;
    requiresPython = project.requires-python;
    pythonSatisfied = builtins.all (
      cond: pyproject-nix.lib.pep440.comparators.${cond.op} pythonVersion cond.version
    ) requiresPython;

    pythonEnv = assert pythonSatisfied
      || throw "Python ${python.pythonVersion} does not satisfy requires-python from pyproject.toml";
      python.withPackages (project.renderers.withPackages {
        inherit python;
      });
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        pythonEnv
      ];
      env = {
        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
          pkgs.stdenv.cc.cc.lib
          pkgs.libz
          pkgs.openssl
        ];
      };
    };
  };
}
