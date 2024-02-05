{
  description = "A collection of nix flake-based development environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-terraform.url = "github:stackbuilders/nixpkgs-terraform";
    flake-utils.url = "github:numtide/flake-utils";
  };

  nixConfig = {
    extra-substituters = "https://nixpkgs-terraform.cachix.org";
    extra-trusted-public-keys = "nixpkgs-terraform.cachix.org-1:8Sit092rIdAVENA3ZVeH9hzSiqI/jng6JiCrQ1Dmusw=";
  };

  outputs = { self, nixpkgs, nixpkgs-terraform, flake-utils }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        terraform = nixpkgs-terraform.packages.${system}."1.7.1";
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
