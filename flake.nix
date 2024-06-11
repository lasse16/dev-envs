{
  description = "A collection of nix flake-based development environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-terraform.url = "github:stackbuilders/nixpkgs-terraform";
    flake-utils.url = "github:numtide/flake-utils";
  };

  nixConfig = {
    extra-substituters = "https://nixpkgs-terraform.cachix.org";
    extra-trusted-public-keys = "nixpkgs-terraform.cachix.org-1:8Sit092rIdAVENA3ZVeH9hzSiqI/jng6JiCrQ1Dmusw=";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-terraform,
    flake-utils,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    versioned-terraform = nixpkgs-terraform.packages.${system}."1.7.4";
  in {
    devShells.${system} = rec {
      bash = pkgs.mkShell {
        name = "bash";
        packages = with pkgs; [shellcheck shfmt];
      };
      nix = pkgs.mkShell {
        name = "nix";
        packages = with pkgs; [nil alejandra statix vulnix deadnix];
      };
      markdown = pkgs.mkShell {
        name = "markdown";
        packages = with pkgs; [ marksman vale ];
      };
      terraform = pkgs.mkShell {
        name = "terraform";
        packages = with pkgs; [terraform-ls tflint terraform-docs versioned-terraform];
      };
      gh-actions = pkgs.mkShell {
     	name = "GitHub Actions" ;
	packages = with pkgs; [yaml-language-server actionlint yamllint];
      };
      lua = pkgs.mkShell {
     	name = "Lua" ;
	packages = with pkgs; [lua-language-server stylua ];
      };
      rust = pkgs.mkShell {
     	name = "Rust" ;
	packages = with pkgs; [ cargo rustc clippy rustfmt rust-analyzer lldb_18 ];
      };
      default = nix;
    };
  };
}
