{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    devShells = forAllSystems (system: let
      pkgs = forAllSystems (system: nixpkgs.legacyPackages.${system});
    in {
      default = pkgs.${system}.mkShellNoCC {
        packages = with pkgs.${system}; [
          package_1
          package_2
        ];
        name = "{{NAME}}";
      };
    });
  };
}
