{
  description = "A collection of nix flake-based development environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        bash = pkgs.mkShell {
          packages = with pkgs; [ shellcheck ];
        };
        terraform = pkgs.mkShell {
          packages = with pkgs;  [ terraform-ls tflint terraform-docs terraform ];
        };
      });
    };
}
