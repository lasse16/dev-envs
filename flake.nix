{
  description = "A collection of nix flake-based development environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    kcl-lsp.url = "github:lasse16/kcl-language-server.nix";
  };

  outputs = {
    self,
    nixpkgs,
    kcl-lsp,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [kcl-lsp.overlays.kcl-language-server];
    };
  in {
    devShells.${system} = rec {
      bash = pkgs.mkShell {
        name = "bash";
        packages = with pkgs; [shellcheck shfmt];
      };
      nix = pkgs.mkShell {
        name = "nix";
        packages = with pkgs; [nil alejandra statix vulnix deadnix nixd];
      };
      markdown = pkgs.mkShell {
        name = "markdown";
        packages = with pkgs; [marksman vale];
      };
      terraform = pkgs.mkShell {
        name = "terraform";
        packages = with pkgs; [terraform-ls tflint terraform-docs];
      };
      gh-actions = pkgs.mkShell {
        name = "GitHub Actions";
        packages = with pkgs; [yaml-language-server actionlint yamllint];
      };
      lua = pkgs.mkShell {
        name = "Lua";
        packages = with pkgs; [lua-language-server stylua];
      };
      rust = pkgs.mkShell {
        name = "Rust";
        packages = with pkgs; [clippy rustfmt rust-analyzer lldb_18];
      };
      python = pkgs.mkShell {
        name = "Python";
        packages = with pkgs; [ruff basedpyright];
      };
      kubernetes = pkgs.mkShell {
        name = "Kubernetes";
        packages = with pkgs; [yaml-language-server yamllint kcl kcl-language-server];
      };
      default = nix;
    };
  };
}
