{
  description = "My Python App with Nix and uv2nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pyproject-nix.follows = "pyproject-nix";
      };
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pyproject-nix.follows = "pyproject-nix";
      };
    };
  };

  outputs = {
    self,
    nixpkgs,
    uv2nix,
    pyproject-nix,
    pyproject-build-systems,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    python = pkgs.python312;

    inherit (pkgs) lib;
    inherit (lib) filterAttrs hasSuffix;

    workspace = uv2nix.lib.workspace.loadWorkspace {
      workspaceRoot = ./.;
    };

    uvLockedOverlay = workspace.mkPyprojectOverlay {
      sourcePreference = "wheel";
    };

    # Placeholder for Your Custom Package Overrides
    myCustomOverrides = final: prev: {
      /*
      e.g., some-package = prev.some-package.overridePythonAttrs (...);
      */
    };

    pythonSet = (pkgs.callPackage pyproject-nix.build.packages {inherit python;})
          .overrideScope (nixpkgs.lib.composeManyExtensions [
      pyproject-build-systems.overlays.default
      uvLockedOverlay
      myCustomOverrides
    ]);

    projectNameInToml = (builtins.fromTOML (builtins.readFile ./pyproject.toml)).project.name;

    thisProjectAsNixPkg = pythonSet.${projectNameInToml};

    appPythonEnv =
      pythonSet.mkVirtualEnv
      (thisProjectAsNixPkg.pname + "-env")
      workspace.deps.default;
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [appPythonEnv pkgs.uv];

      env = {
        UV_NO_SYNC = "1";
        UV_PYTHON = pythonSet.python.interpreter;
        UV_PYTHON_DOWNLOADS = "never";
      };

      shellHook = ''
        unset PYTHONPATH
        export REPO_ROOT=$(git rev-parse --show-toplevel)
      '';
    };

    devShells.${system}.bootstrap = pkgs.mkShell {
      packages = [python pkgs.uv];

      env = {
        UV_NO_SYNC = "1";
        UV_PYTHON = pythonSet.python.interpreter;
        UV_PYTHON_DOWNLOADS = "never";
      };

      shellHook = ''
        unset PYTHONPATH
        export REPO_ROOT=$(git rev-parse --show-toplevel)
      '';
    };

    packages.default = pkgs.stdenv.mkDerivation {
      pname = thisProjectAsNixPkg.pname;
      version = thisProjectAsNixPkg.version;
      src = ./.;

      nativeBuildInputs = [pkgs.makeWrapper];
      buildInputs = [appPythonEnv];

      installPhase = ''
        mkdir -p $out/bin
        cp main.py $out/bin/${thisProjectAsNixPkg.pname}-script
        chmod +x $out/bin/${thisProjectAsNixPkg.pname}-script
        makeWrapper ${appPythonEnv}/bin/python $out/bin/${thisProjectAsNixPkg.pname} \
          --add-flags $out/bin/${thisProjectAsNixPkg.pname}-script
      '';
    };
    packages.${thisProjectAsNixPkg.pname} = self.packages.${system}.default;

    apps.${system}.default = {
      type = "app";
      program = "${self.packages.${system}.default}/bin/${thisProjectAsNixPkg.pname}";
    };
    apps.${system}.${thisProjectAsNixPkg.pname} = self.apps.${system}.default;

    apps.${system} = let
      examples_dir = ./examples;
      python_files_in_examples = filterAttrs (name: type: type == "regular" && hasSuffix ".py" name) (builtins.readDir examples_dir);
    in
      lib.mapAttrs' (
        name: _:
          lib.NameValuePair (lib.removeSuffix ".py" name) (
            let
              script = examples_dir + "/${name}";
              program = pkgs.runCommand name {buildInputs = [appPythonEnv];} ''
                cp ${script} $out
                chmod +x $out
                patchShebangs $out
              '';
            in {
              type = "app";
              program = "${program}";
            }
          )
      )
      python_files_in_examples;
  };
}
